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
        XCTAssertEqual(String(bytes: data, encoding: .utf8), "2345")
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
        let text = try XCTUnwrap(String(bytes: data, encoding: .utf8))
        let segment = try XCTUnwrap(text.components(separatedBy: .newlines).first(where: { $0.hasPrefix("http://") }).flatMap(URL.init(string:)))
        XCTAssertEqual(segment.host, "127.0.0.1")
        XCTAssertNotEqual(segment.port, fixture.base.port)
        XCTAssertFalse(text.contains("secret"))
        let (segmentData, _) = try await URLSession.shared.data(from: segment)
        XCTAssertEqual(String(bytes: segmentData, encoding: .utf8), "0123456789")
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
        XCTAssertEqual(String(bytes: redirectedBody, encoding: .utf8), "0123456789")
        XCTAssertEqual(other.requests.count, 1)
        XCTAssertFalse(try XCTUnwrap(other.requests.first).lowercased().contains("cookie:"))
    }

    func testRootAndDeclaredChildPlaylistKeepTheirRoleAcrossTextRedirects() async throws {
        let fixture = try await MediaHTTPFixture.start()
        let external = try await MediaHTTPFixture.start()
        defer { fixture.stop(); external.stop() }
        fixture.respond("/root.m3u8", status: 302, headers: ["Location": fixture.base.appending(path: "master-content").absoluteString])
        fixture.respond("/master-content", body: "#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=200000\nchild\n")
        fixture.respond("/child", status: 302, headers: ["Location": fixture.base.appending(path: "child-content").absoluteString])
        fixture.respond("/child-content", body: "#EXTM3U\n#EXT-X-TARGETDURATION:10\n#EXTINF:10,\n\(external.base)/segment.ts\n#EXT-X-ENDLIST\n")
        let sentinel = try XCTUnwrap(HTTPCookie(properties: [.domain: "127.0.0.1", .path: "/", .name: "jwt", .value: "shared-sentinel"]))
        HTTPCookieStorage.shared.setCookie(sentinel)
        defer { HTTPCookieStorage.shared.deleteCookie(sentinel) }
        let proxy = LectureMediaProxy(policy: .init(origin: fixture.base, token: "captured"), isCurrent: { true })
        defer { proxy.stop() }
        let root = try await proxy.start(source: fixture.base.appending(path: "root.m3u8"))
        let (main, _) = try await URLSession.shared.data(from: root)
        let rootPlaylist = try XCTUnwrap(String(bytes: main, encoding: .utf8))
        let child = try XCTUnwrap(rootPlaylist.split(separator: "\n").last.flatMap { URL(string: String($0)) })
        XCTAssertEqual(child.port, root.port)
        let (playlist, response) = try await URLSession.shared.data(from: child)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        let text = try XCTUnwrap(String(bytes: playlist, encoding: .utf8))
        XCTAssertFalse(text.contains(external.base.absoluteString))
        let segment = try XCTUnwrap(text.components(separatedBy: .newlines).first(where: { $0.hasPrefix("http://") }).flatMap(URL.init(string:)))
        XCTAssertEqual(segment.port, root.port)
        _ = try await URLSession.shared.data(from: segment)
        XCTAssertFalse(try XCTUnwrap(external.requests.first).lowercased().contains("cookie:"))
        XCTAssertFalse(fixture.requests.contains { $0.lowercased().contains("range:") })
    }

    func testUnexpectedPlaylistCannotEscapeThroughAMediaRoute() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        fixture.respond("/video.mp4", body: "#EXTM3U\nhttps://remote.example/segment.ts\n")
        let proxy = LectureMediaProxy(policy: .init(origin: fixture.base, token: nil), isCurrent: { true })
        defer { proxy.stop() }
        let local = try await proxy.start(source: fixture.base.appending(path: "video.mp4"))
        let (data, response) = try await URLSession.shared.data(from: local)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 502)
        XCTAssertFalse(try XCTUnwrap(String(bytes: data, encoding: .utf8)).contains("remote.example"))
    }

    func testLongMultirenditionVODHasNoLifetimeRouteQuota() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        fixture.respond("/long.m3u8", body: "#EXTM3U\n" + (0..<4).map { "#EXT-X-STREAM-INF:BANDWIDTH=\(100_000 + $0)\ntrack-\($0).m3u8" }.joined(separator: "\n"))
        for track in 0..<4 {
            let segments = (0..<5400).map { "#EXTINF:2,\nsegment-\($0).ts?track=\(track)" }.joined(separator: "\n")
            fixture.respond("/track-\(track).m3u8", body: "#EXTM3U\n#EXT-X-TARGETDURATION:2\n" + segments + "\n#EXT-X-ENDLIST\n")
        }
        let proxy = LectureMediaProxy(policy: .init(origin: fixture.base, token: nil), isCurrent: { true })
        defer { proxy.stop() }
        let root = try await proxy.start(source: fixture.base.appending(path: "long.m3u8"))
        let (main, _) = try await URLSession.shared.data(from: root)
        for line in try XCTUnwrap(String(bytes: main, encoding: .utf8)).components(separatedBy: .newlines) where line.hasPrefix("http") {
            let (_, response) = try await URLSession.shared.data(from: XCTUnwrap(URL(string: line)))
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        }
    }

    func testRollingSignedWindowsReclaimOldRoutesAndKeepRepeatedRangeIdentity() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let proxy = LectureMediaProxy(policy: .init(origin: fixture.base, token: nil), isCurrent: { true })
        defer { proxy.stop() }
        let root = try await proxy.start(source: fixture.base.appending(path: "live.m3u8"))
        var first: URL?
        var current: URL?
        for generation in 0..<30 {
            let segments = (0..<100).map { "#EXTINF:2,\nsegment-\($0).ts?signature=\(generation)" }.joined(separator: "\n")
            fixture.respond("/live.m3u8", body: "#EXTM3U\n#EXT-X-TARGETDURATION:2\n" + segments + "\n#EXT-X-BYTERANGE:2@0\nshared.ts\n#EXT-X-BYTERANGE:2\nshared.ts\n")
            let (data, response) = try await URLSession.shared.data(from: root)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            let routes = try XCTUnwrap(String(bytes: data, encoding: .utf8)).components(separatedBy: .newlines).filter { $0.hasPrefix("http") }
            XCTAssertEqual(routes.suffix(2).first, routes.last)
            current = routes.first.flatMap(URL.init(string:))
            if first == nil { first = current }
        }
        let (_, removed) = try await URLSession.shared.data(from: XCTUnwrap(first))
        XCTAssertEqual((removed as? HTTPURLResponse)?.statusCode, 404)
        let (_, available) = try await URLSession.shared.data(from: XCTUnwrap(current))
        XCTAssertEqual((available as? HTTPURLResponse)?.statusCode, 200)
    }

    func testBOMPrefixedWebVTTPreservesItsOriginalBytes() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let body = "\u{feff}WEBVTT\n\n00:00:00.000 --> 00:00:01.000\nCaption\n"
        fixture.respond("/master.m3u8", body: "#EXTM3U\n#EXTINF:1,\ncaptions.vtt\n#EXT-X-ENDLIST\n")
        fixture.respond("/captions.vtt", body: body, mime: "text/vtt")
        let proxy = LectureMediaProxy(policy: .init(origin: fixture.base, token: nil), isCurrent: { true })
        defer { proxy.stop() }
        let root = try await proxy.start(source: fixture.base.appending(path: "master.m3u8"))
        let (playlist, _) = try await URLSession.shared.data(from: root)
        let text = try XCTUnwrap(String(bytes: playlist, encoding: .utf8))
        let route = try XCTUnwrap(text.components(separatedBy: .newlines).first(where: { $0.hasPrefix("http") }).flatMap(URL.init(string:)))
        let (data, response) = try await URLSession.shared.data(from: route)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(data, Data(body.utf8))
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
    var responses: [String: Data] = [:]
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

    func respond(_ path: String, body: String = "", mime: String = "text/plain", status: Int = 200, headers: [String: String] = [:]) {
        var response = "HTTP/1.1 \(status) Response\r\nContent-Type: \(mime)\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n"
        for (key, value) in headers { response += "\(key): \(value)\r\n" }
        responses[path] = Data((response + "\r\n" + body).utf8)
    }

    private func receive(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) { [weak self] data, _, _, _ in
            guard let self, let data else { return }
            let buffer = buffer + data
            guard let request = String(data: buffer, encoding: .utf8), request.contains("\r\n\r\n") else {
                self.receive(connection, buffer: buffer); return
            }
            self.requests.append(request)
            let path = String(request.split(separator: " ")[1]).components(separatedBy: "?")[0]
            if let response = self.responses[path] {
                connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
                return
            }
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
