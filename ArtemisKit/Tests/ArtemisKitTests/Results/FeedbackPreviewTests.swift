import XCTest
@testable import CourseView

final class FeedbackPreviewTests: XCTestCase {
    func testLongFeedbackPreviewKeepsLoadActionCloseAndPreservesUnicode() {
        let text = String(repeating: "👩‍💻e\u{301}", count: 500)
        let preview = ReviewMessagePreview(text)
        XCTAssertTrue(preview.isTruncated)
        XCTAssertLessThanOrEqual(preview.collapsed.count, 401)
        XCTAssertTrue(text.hasPrefix(String(preview.collapsed.dropLast())))
        XCTAssertEqual(preview.full, text)
    }
    func testPreviewBoundsManyShortParagraphsAndLeavesShortFeedbackUnchanged() {
        let preview = ReviewMessagePreview((1...100).map { "Paragraph \($0)" }.joined(separator: "\n"))
        XCTAssertLessThanOrEqual(preview.collapsed.components(separatedBy: "\n").count, 6)
        XCTAssertTrue(preview.isTruncated)
        XCTAssertEqual(ReviewMessagePreview("Short feedback").collapsed, "Short feedback")
        XCTAssertFalse(ReviewMessagePreview("Short feedback").isTruncated)
    }
}
