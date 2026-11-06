import XCTest
@testable import CourseView

final class LectureMediaPrefixTests: XCTestCase {
    func testSplitBOMWaitsAndValidWebVTTRemainsMedia() {
        XCTAssertEqual(LectureMediaPrefix.classify(Data([0xef])), .waiting)
        XCTAssertEqual(LectureMediaPrefix.classify(Data([0xef, 0xbb])), .waiting)
        XCTAssertEqual(LectureMediaPrefix.classify(Data([0xef, 0xbb, 0xbf])), .waiting)
        XCTAssertEqual(LectureMediaPrefix.classify(Data("\u{feff}WEBVTT".utf8)), .media)
    }

    func testBOMPrefixedAndSplitManifestIsRejectedBeforeStreaming() {
        XCTAssertEqual(LectureMediaPrefix.classify(Data("\u{feff}#EXT".utf8)), .waiting)
        XCTAssertEqual(LectureMediaPrefix.classify(Data("\u{feff}#EXTM3U\nhttps://external.example/a.ts".utf8)), .reject)
    }
}
