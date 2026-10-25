import AVKit
import Foundation
import Network
import XCTest
@testable import CourseView

@MainActor
final class LectureMediaProxyTests: XCTestCase {
    func testRangeStreamingUsesCapturedCredentialsAndIgnoresPlayerCookies() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let source = fixture.base.appending(path: "video.mp4")
        let proxy = LectureMediaProxy(policy: .init(origin: fixture.base, token: "account-a"), isCurrent: { true })
        defer { proxy.stop() }
        let url = try await proxy.start(source: source)
        var request = URLRequest(url: url)
        request.setValue("bytes=2-5", forHTTPHeaderField: "Range")
        request.setValue("jwt=must-not-forward", forHTTPHeaderField: "Cookie")
        request.setValue("Bearer must-not-forward", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "2345")
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 206)
        XCTAssertEqual((response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Range"), "bytes 2-5/10")
        XCTAssertTrue(fixture.requests[0].contains("Cookie: jwt=account-a"))
        XCTAssertFalse(fixture.requests[0].contains("must-not-forward"))
    }

    func testExternalOriginAndDifferentPortNeverReceiveArtemisCredentials() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let proxy = LectureMediaProxy(policy: .init(origin: URL(string: "http://127.0.0.1:1")!, token: "private"), isCurrent: { true })
        defer { proxy.stop() }
        let url = try await proxy.start(source: fixture.base.appending(path: "video.mp4"))
        _ = try await URLSession.shared.data(from: url)
        XCTAssertFalse(fixture.requests[0].lowercased().contains("cookie:"))
    }

    func testOpaqueRoutesRejectArbitraryURLsAndMultipleRanges() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let proxy = LectureMediaProxy(policy: .init(origin: fixture.base, token: nil), isCurrent: { true })
        defer { proxy.stop() }
        let url = try await proxy.start(source: fixture.base.appending(path: "video.mp4"))
        let (_, response) = try await URLSession.shared.data(from: URL(string: url.absoluteString + "?url=https://example.org")!)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 404)
        var request = URLRequest(url: url)
        request.setValue("bytes=0-1,3-4", forHTTPHeaderField: "Range")
        let (_, badRange) = try await URLSession.shared.data(for: request)
        XCTAssertEqual((badRange as? HTTPURLResponse)?.statusCode, 400)
        XCTAssertTrue(fixture.requests.isEmpty)
    }

    func testHLSPlaylistRewritesToOpaqueRoutesAndSegmentsLoad() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let proxy = LectureMediaProxy(policy: .init(origin: fixture.base, token: "private"), isCurrent: { true })
        defer { proxy.stop() }
        let url = try await proxy.start(source: fixture.base.appending(path: "master.m3u8"))
        var sniff = URLRequest(url: url)
        sniff.setValue("bytes=0-1", forHTTPHeaderField: "Range")
        let (data, response) = try await URLSession.shared.data(for: sniff)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        let text = String(decoding: data, as: UTF8.self)
        let segment = try XCTUnwrap(text.components(separatedBy: .newlines).first(where: { $0.hasPrefix("http://") }).flatMap(URL.init(string:)))
        XCTAssertEqual(segment.host, "127.0.0.1")
        XCTAssertNotEqual(segment.port, fixture.base.port)
        XCTAssertFalse(text.contains("secret"))
        let (segmentData, _) = try await URLSession.shared.data(from: segment)
        XCTAssertEqual(String(decoding: segmentData, as: UTF8.self), "0123456789")
        XCTAssertEqual(fixture.requests.count, 2)
    }

    func testHeadPreservesLengthWithoutBodyAndProtectedRedirectCannotLeakCookies() async throws {
        let fixture = try await MediaHTTPFixture.start()
        let other = try await MediaHTTPFixture.start()
        defer { fixture.stop(); other.stop() }
        let proxy = LectureMediaProxy(policy: .init(origin: fixture.base, token: "private"), isCurrent: { true })
        defer { proxy.stop() }
        let url = try await proxy.start(source: fixture.base.appending(path: "video.mp4"))
        var head = URLRequest(url: url)
        head.httpMethod = "HEAD"
        let (body, response) = try await URLSession.shared.data(for: head)
        XCTAssertTrue(body.isEmpty)
        XCTAssertEqual((response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Length"), "10")
        fixture.redirectURL = other.base.appending(path: "video.mp4")
        let redirectProxy = LectureMediaProxy(policy: .init(origin: fixture.base, token: "private"), isCurrent: { true })
        defer { redirectProxy.stop() }
        let redirect = try await redirectProxy.start(source: fixture.base.appending(path: "redirect.mp4"))
        let (redirectedBody, redirectedResponse) = try await URLSession.shared.data(from: redirect)
        XCTAssertEqual((redirectedResponse as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(String(decoding: redirectedBody, as: UTF8.self), "0123456789")
        XCTAssertEqual(other.requests.count, 1)
        XCTAssertFalse(try XCTUnwrap(other.requests.first).lowercased().contains("cookie:"))
    }

    func testStoppedOrChangedSessionCannotStartPlayback() async throws {
        let proxy = LectureMediaProxy(policy: .init(origin: URL(string: "https://example.org")!, token: "private"), isCurrent: { false })
        do {
            _ = try await proxy.start(source: URL(string: "https://example.org/video.mp4")!)
            XCTFail("A stale account must not start a media server")
        } catch { }
    }
}

/// Deterministic local upstream, kept entirely in the test target.
final class MediaHTTPFixture {
    let listener: NWListener
    var base: URL { URL(string: "http://127.0.0.1:\(listener.port?.rawValue ?? 0)")! }
    var requests: [String] = []
    var redirectURL: URL?
    private var connections: [NWConnection] = []

    init(listener: NWListener) { self.listener = listener }

    static func start() async throws -> MediaHTTPFixture {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
        let listener = try NWListener(using: parameters)
        let fixture = MediaHTTPFixture(listener: listener)
        listener.newConnectionHandler = { [weak fixture] connection in
            fixture?.connections.append(connection)
            connection.start(queue: .main)
            fixture?.receive(connection, buffer: Data())
        }
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UInt16, Error>) in
            let startup = FixtureStartup(continuation)
            listener.stateUpdateHandler = { [weak listener] state in
                if case .ready = state, let port = listener?.port?.rawValue { startup.finish(.success(port)) }
                if case .failed(let error) = state { startup.finish(.failure(error)) }
            }
            listener.start(queue: .main)
        }
        return fixture
    }

    func stop() { listener.cancel(); connections.forEach { $0.cancel() } }

    private func receive(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] data, _, _, _ in
            guard let self, let data else { return }
            let buffer = buffer + data
            guard let request = String(data: buffer, encoding: .utf8), request.contains("\r\n\r\n") else {
                self.receive(connection, buffer: buffer); return
            }
            self.requests.append(request)
            if request.contains("/redirect.mp4"), let destination = self.redirectURL {
                let response = "HTTP/1.1 302 Found\r\nLocation: \(destination.absoluteString)\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
                connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in connection.cancel() })
                return
            }
            let isPlaylist = request.contains("/master.m3u8")
            let partial = request.lowercased().contains("range: bytes=2-5")
            let body = isPlaylist ? "#EXTM3U\n#EXT-X-TARGETDURATION:10\n#EXTINF:10,\nsegment.ts?token=secret\n#EXT-X-ENDLIST\n" : (partial ? "2345" : "0123456789")
            let mime = isPlaylist ? "application/vnd.apple.mpegurl" : "video/mp4"
            var header = "HTTP/1.1 \(partial ? "206 Partial Content" : "200 OK")\r\nContent-Type: \(mime)\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n"
            if partial { header += "Content-Range: bytes 2-5/10\r\n" }
            let payload = request.hasPrefix("HEAD ") ? Data((header + "\r\n").utf8) : Data((header + "\r\n" + body).utf8)
            connection.send(content: payload, completion: .contentProcessed { _ in connection.cancel() })
        }
    }
}

private final class FixtureStartup: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<UInt16, Error>?
    init(_ continuation: CheckedContinuation<UInt16, Error>) { self.continuation = continuation }
    func finish(_ result: Result<UInt16, Error>) {
        let pending = lock.withLock { let value = continuation; continuation = nil; return value }
        pending?.resume(with: result)
    }
}

@MainActor
final class LectureVideoLifecycleTests: XCTestCase {
    func testPreparationDoesNotAutoplayAndClosingReleasesTheItem() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let snapshot = LectureMediaSession(account: "test", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString, snapshot: snapshot, isCurrent: { true })
        await model.load()
        let player = try XCTUnwrap(model.player)
        XCTAssertEqual(player.rate, 0)
        model.stop()
        XCTAssertNil(model.player)
        XCTAssertNil(player.currentItem)
    }

    func testLateFailureFromPreviousItemCannotCancelARetry() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let snapshot = LectureMediaSession(account: "test", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString, snapshot: snapshot, isCurrent: { true })
        defer { model.stop() }
        await model.load()
        let oldItem = try XCTUnwrap(model.player?.currentItem)
        // Queue the old notification's main-actor work just before retry yields.
        NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: oldItem)
        await model.load()
        XCTAssertNotNil(model.player)
        XCTAssertEqual(model.state, .loading)
    }

    func testFailedMediaCanCreateANewPausedPlayerOnRetry() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let snapshot = LectureMediaSession(account: "test", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString, snapshot: snapshot, isCurrent: { true })
        defer { model.stop() }
        await model.load()
        for _ in 0..<100 {
            if case .failed = model.state { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        guard case .failed = model.state else { XCTFail("Invalid media must produce a recoverable failure"); return }
        let oldPlayer = model.player
        await model.load()
        XCTAssertNotNil(model.player)
        XCTAssertFalse(model.player === oldPlayer)
        XCTAssertEqual(model.player?.rate, 0)
        XCTAssertNil(oldPlayer?.currentItem)
    }

    func testSessionChangeCancelsPlayerAndLatePreparation() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        var current = true
        let snapshot = LectureMediaSession(account: "test", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString, snapshot: snapshot, isCurrent: { current })
        let loading = Task { await model.load() }
        await Task.yield()
        current = false
        model.sessionChanged()
        await loading.value
        XCTAssertNil(model.player)
        if case .failed = model.state {} else { XCTFail("A changed session must be visible as an error") }
        model.stop()
    }
}
