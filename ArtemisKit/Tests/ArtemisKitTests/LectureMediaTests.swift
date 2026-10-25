import XCTest
@testable import CourseView
@testable import Navigation

final class LectureMediaTests: XCTestCase {
    func testSourceClassificationParsesPathAndRejectsUnsafeSchemes() {
        XCTAssertEqual(LectureMediaSource.classify(URL(string: "https://example.org/VIDEO.MP4?signature=secret")!), .video)
        XCTAssertEqual(LectureMediaSource.classify(URL(string: "https://example.org/live.m3u8?token=secret")!), .video)
        XCTAssertEqual(LectureMediaSource.classify(URL(string: "https://example.org/watch?id=2")!), .web)
        XCTAssertEqual(LectureMediaSource.classify(URL(string: "https://example.org/download")!, mimeType: "video/mp4"), .video)
        XCTAssertEqual(LectureMediaSource.classify(URL(string: "https://example.org/MASTER.M3U?token=secret")!), .video)
        for value in ["javascript:alert(1)", "file:///video.mp4", "data:video/mp4,a", "https://user:pass@example.org/a"] {
            XCTAssertEqual(LectureMediaSource.classify(URL(string: value)!), .invalid)
        }
    }

    func testCredentialsRequireExactOriginIncludingSchemeAndPort() {
        let base = URL(string: "https://example.org")!
        XCTAssertTrue(LectureMediaOrigin.matches(base, URL(string: "https://EXAMPLE.org:443/media")!))
        XCTAssertFalse(LectureMediaOrigin.matches(base, URL(string: "http://example.org/media")!))
        XCTAssertFalse(LectureMediaOrigin.matches(base, URL(string: "https://example.org:8443/media")!))
        XCTAssertFalse(LectureMediaOrigin.matches(base, URL(string: "https://cdn.example.org/media")!))
        let policy = LectureMediaRequestPolicy(origin: base, token: "secret")
        XCTAssertEqual(policy.request(for: base).value(forHTTPHeaderField: "Cookie"), "jwt=secret")
        XCTAssertNil(policy.request(for: URL(string: "http://example.org")!).value(forHTTPHeaderField: "Cookie"))
        let redirect = policy.redirect(from: base, to: URL(string: "https://cdn.example.org")!)
        XCTAssertEqual(redirect?.url?.host, "cdn.example.org")
        XCTAssertNil(redirect?.value(forHTTPHeaderField: "Cookie"))
    }

    func testProgressSeparatesAccountAndOriginAndDoesNotPersistSignedURL() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let a = LectureMediaProgress(account: "alice", server: URL(string: "https://example.org")!, identity: "course/1/lecture/2/unit/3", defaults: defaults)
        let b = LectureMediaProgress(account: "bob", server: URL(string: "https://example.org")!, identity: "course/1/lecture/2/unit/3", defaults: defaults)
        let other = LectureMediaProgress(account: "alice", server: URL(string: "http://example.org")!, identity: "course/1/lecture/2/unit/3", defaults: defaults)
        a.save(page: 7)
        a.save(seconds: 42)
        XCTAssertEqual(a.pageIndex(explicitPage: nil, pageCount: 10), 7)
        XCTAssertEqual(a.seconds, 42)
        XCTAssertEqual(b.seconds, 0)
        XCTAssertEqual(other.pageIndex(explicitPage: nil, pageCount: 10), 0)
    }

    func testExplicitReferenceUsesOneBasedPageAndOverridesRememberedPage() {
        let store = LectureMediaProgress(account: "alice", server: URL(string: "https://example.org")!, identity: UUID().uuidString)
        store.save(page: 7)
        XCTAssertEqual(store.pageIndex(explicitPage: 3, pageCount: 10), 2)
        XCTAssertEqual(store.pageIndex(explicitPage: 0, pageCount: 10), 0)
        XCTAssertEqual(store.pageIndex(explicitPage: 99, pageCount: 10), 9)
        XCTAssertEqual(store.pageIndex(explicitPage: nil, pageCount: 0), 0)
    }

    func testNewLoadAndCancellationRejectLateResults() {
        var load = LectureMediaLoadGeneration()
        let old = load.begin()
        let new = load.begin()
        XCTAssertFalse(load.accepts(old))
        XCTAssertTrue(load.accepts(new))
        load.cancel()
        XCTAssertFalse(load.accepts(new))
    }

    @MainActor
    func testDeepLinkDispatchesTheActualUnitAndPage() async throws {
        let controller = NavigationController()
        let handler = try XCTUnwrap(LectureHandler.build(from: URL(string: "https://example.org/courses/1/lectures/2?lectureUnitId=5&page=3")!))
        handler.handle(with: controller)
        for _ in 0..<20 {
            if controller.selectedPath is LecturePath { break }
            await Task.yield()
        }
        let path = try XCTUnwrap(controller.selectedPath as? LecturePath)
        XCTAssertEqual(path.id, 2)
        XCTAssertEqual(path.target?.unitId, 5)
        XCTAssertEqual(path.target?.page, 3)
    }

    func testDeepLinkRetainsUnitAndPage() {
        let link = LectureHandler.build(from: URL(string: "https://example.org/courses/1/lectures/2?lectureUnitId=5&page=3")!)
        XCTAssertEqual(link?.target, LectureMediaTarget(unitId: 5, page: 3))
    }
}

final class LectureMediaPlaylistTests: XCTestCase {
    func testPlaylistRewritesRelativeVariantsSegmentsKeysAndSubtitles() throws {
        let playlist = "#EXTM3U\n#EXT-X-MEDIA:TYPE=SUBTITLES,URI=\"captions/en.m3u8\"\n#EXT-X-KEY:METHOD=AES-128,URI=\"../key\"\n#EXT-X-MAP:URI=\"init.mp4\"\n#EXT-X-STREAM-INF:BANDWIDTH=200000\nlow/index.m3u8?token=secret\nsegment.ts\n"
        var destinations: [String] = []
        let rewritten = try LectureMediaPlaylist.rewrite(playlist, relativeTo: URL(string: "https://media.example.org/course/master.m3u8")!) { url in
            destinations.append(url.absoluteString)
            return URL(string: "http://127.0.0.1:1234/resource/\(destinations.count)")!
        }
        XCTAssertEqual(destinations, ["https://media.example.org/course/captions/en.m3u8", "https://media.example.org/key", "https://media.example.org/course/init.mp4", "https://media.example.org/course/low/index.m3u8?token=secret", "https://media.example.org/course/segment.ts"])
        XCTAssertFalse(rewritten.contains("secret"))
        XCTAssertTrue(rewritten.contains("URI=\"http://127.0.0.1:1234/resource/1\""))
    }

    func testPlaylistRejectsNonNetworkResourcesAndUnsupportedDRM() {
        for playlist in ["#EXTM3U\nfile:///secret", "#EXTM3U\n#EXT-X-KEY:METHOD=SAMPLE-AES,URI=\"skd://protected\"", "<html>login</html>", "#EXTM3U\n#EXT-X-FUTURE-STREAM:URL=\"https://remote.example/video\"", "#EXTM3U\n#EXT-X-KEY:METHOD=AES-128,URI=https://remote.example/key"] {
            XCTAssertThrowsError(try LectureMediaPlaylist.rewrite(playlist, relativeTo: URL(string: "https://example.org/master.m3u8")!) { $0 })
        }
    }

    func testProxyRequestOnlyAllowsSingleSafeByteRange() {
        XCTAssertTrue(LectureMediaProxyRequest.validRange("bytes=0-99"))
        XCTAssertTrue(LectureMediaProxyRequest.validRange("bytes=100-"))
        XCTAssertTrue(LectureMediaProxyRequest.validRange("bytes=-50"))
        for range in ["bytes=-", "bytes=3-1", "bytes=0-1,3-4", "bytes=1-2\r\nCookie: secret"] {
            XCTAssertFalse(LectureMediaProxyRequest.validRange(range))
        }
    }
}
