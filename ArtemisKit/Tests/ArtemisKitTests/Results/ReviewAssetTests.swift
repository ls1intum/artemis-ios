import Foundation
import Network
import XCTest
@testable import CourseView
@testable import ReviewContent

final class ReviewAssetTests: XCTestCase {
    func testActualReviewAssetRequestsRejectForeignOriginsRedirectsCookiesAndCaching() async throws {
        let server = try ReviewHTTPFixture(); try await server.start(); defer { server.stop() }
        let captured = ReviewSession(baseURL: server.baseURL, username: "owner", token: "captured-token")
        let transport = ReviewTransport(captured: captured, currentSession: { captured }); defer { transport.invalidate() }
        var denied = false
        let assets = ReviewAssetContext(baseURL: server.baseURL, isCurrent: { transport.isCurrent }, load: { try await transport.data($0) }, didFail: { error in
            if case ReviewError.denied = error { denied = true }
        })
        let cookie = try XCTUnwrap(HTTPCookie(properties: [.domain: "127.0.0.1", .path: "/", .name: "unrelated", .value: "private-cookie"]))
        HTTPCookieStorage.shared.setCookie(cookie); defer { HTTPCookieStorage.shared.deleteCookie(cookie) }
        _ = try await assets.data(path: "/image")
        _ = try await assets.data(path: "/image")
        XCTAssertEqual(server.requests.filter { $0.hasPrefix("GET /image ") }.count, 2, "Asset responses must not persist or be reused from URLCache")
        XCTAssertTrue(server.requests.allSatisfy { !$0.lowercased().contains("cookie:") })
        XCTAssertTrue(server.requests.allSatisfy { $0.contains("Authorization: Bearer captured-token") })
        do { _ = try await assets.data(path: "https://other.example/image"); XCTFail("Foreign image fetched") } catch { }
        do { _ = try await assets.data(path: "/redirect"); XCTFail("Redirect followed") } catch { }
        XCTAssertEqual(server.requests.filter { $0.hasPrefix("GET /redirect-target ") }.count, 0)
        do { _ = try await assets.data(path: "/denied"); XCTFail("Denied image returned") } catch { }
        XCTAssertTrue(denied, "Asset access loss must notify the review owner so protected content can be cleared")
    }
    func testAssetResponseIsDiscardedWhenCapturedSessionChangesDuringRequest() async throws {
        let server = try ReviewHTTPFixture(); try await server.start(); defer { server.stop() }
        let current = ReviewCurrentSessionBox()
        let captured = ReviewSession(baseURL: server.baseURL, username: "owner", token: "captured-token")
        current.value = captured
        let transport = ReviewTransport(captured: captured, currentSession: { current.value }); defer { transport.invalidate() }
        let assets = ReviewAssetContext(baseURL: server.baseURL, isCurrent: { transport.isCurrent }, load: { try await transport.data($0) })
        let received = expectation(description: "Image request reached server")
        server.hold = { received.fulfill() }
        let task = Task { try await assets.data(path: "/held-image") }
        await fulfillment(of: [received], timeout: 3)
        current.value = nil
        server.releaseHeld()
        do { _ = try await task.value; XCTFail("Old account image returned") } catch { }
    }
    func testQuizArtifactResolutionKeepsCapturedOriginAndRejectsCredentialURLs() throws {
        let assets = ReviewAssetContext(baseURL: URL(string: "https://one.example")!, isCurrent: { true }, load: { _ in Data() })
        XCTAssertEqual(try assets.resolve("drag-and-drop/backgrounds/a.png", filePath: true).path, "/api/core/files/drag-and-drop/backgrounds/a.png")
        XCTAssertThrowsError(try assets.resolve("https://user:password@one.example/a.png"))
        XCTAssertThrowsError(try assets.resolve("//other.example/a.png"))
    }
}

private final class ReviewCurrentSessionBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: ReviewSession?
    var value: ReviewSession? {
        get { lock.lock(); defer { lock.unlock() }; return stored }
        set { lock.lock(); defer { lock.unlock() }; stored = newValue }
    }
}

/// Actual HTTP fixture: URLSession's native redirect/cookie/cache handling is exercised, not mocked.
private final class ReviewHTTPFixture: @unchecked Sendable {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "review.http.fixture")
    private let lock = NSLock()
    private var received: [String] = []
    private var held: NWConnection?
    var hold: (() -> Void)?
    var requests: [String] { lock.lock(); defer { lock.unlock() }; return received }
    var baseURL: URL { URL(string: "http://127.0.0.1:\(listener.port!.rawValue)")! }
    init() throws { listener = try NWListener(using: .tcp, on: .any) }
    func start() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            listener.stateUpdateHandler = { state in
                switch state {
                case .ready: continuation.resume()
                case .failed(let error): continuation.resume(throwing: error)
                default: break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                connection.start(queue: self?.queue ?? .global())
                self?.receive(connection, prefix: Data())
            }
            listener.start(queue: queue)
        }
    }
    private func receive(_ connection: NWConnection, prefix: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, _, _ in
            guard let self, let data else { return }
            let combined = prefix + data
            guard let request = String(bytes: combined, encoding: .utf8) else { return }
            guard request.contains("\r\n\r\n") else { self.receive(connection, prefix: combined); return }
            self.lock.lock(); self.received.append(request); self.lock.unlock()
            if request.hasPrefix("GET /held-image ") {
                self.lock.lock(); self.held = connection; self.lock.unlock(); self.hold?()
            } else if request.hasPrefix("GET /redirect ") {
                self.send(connection, response: "HTTP/1.1 302 Found\r\nLocation: /redirect-target\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
            } else if request.hasPrefix("GET /denied ") {
                self.send(connection, response: "HTTP/1.1 403 Forbidden\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
            } else { self.sendImage(connection) }
        }
    }
    private func sendImage(_ connection: NWConnection) {
        send(connection, response: "HTTP/1.1 200 OK\r\nContent-Length: 4\r\nCache-Control: max-age=3600\r\nSet-Cookie: server-cookie=secret; Path=/\r\nConnection: close\r\n\r\npng!")
    }
    private func send(_ connection: NWConnection, response: String) {
        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in connection.cancel() })
    }
    func releaseHeld() { lock.lock(); let connection = held; held = nil; lock.unlock(); if let connection { sendImage(connection) } }
    func stop() { listener.cancel(); lock.lock(); held?.cancel(); held = nil; lock.unlock() }
}
