import XCTest
@testable import CourseView

final class LectureMediaPlaylistTests: XCTestCase {
    func testPlaylistRewritesRelativeVariantsSegmentsKeysAndSubtitles() throws {
        let playlist = "#EXTM3U\n#EXT-X-MEDIA:TYPE=SUBTITLES,URI=\"captions/en.m3u8\"\n"
            + "#EXT-X-KEY:METHOD=AES-128,URI=\"../key\"\n#EXT-X-MAP:URI=\"init.mp4\"\n"
            + "#EXT-X-STREAM-INF:BANDWIDTH=200000\nlow/index.m3u8?token=secret\nsegment.ts\n"
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
