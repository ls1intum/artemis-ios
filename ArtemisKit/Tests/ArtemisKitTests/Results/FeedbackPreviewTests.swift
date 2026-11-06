import SwiftUI
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
    @MainActor
    func testAccessibilityReferenceActionUsesItsFullMultilineHeight() throws {
        let feedback = try JSONDecoder().decode(StudentFeedback.self, from: Data(#"{"text":"Feedback","credits":5}"#.utf8))
        let action = "Show the assessed passage and the complete context for this detailed assessment comment"
        let row = FeedbackReviewRow(feedback: feedback, selected: false, loading: false, failed: false,
                                    referenceLabel: action, unlocated: false, onSelect: {}, onLong: {})
            .environment(\.dynamicTypeSize, .accessibility3)
        let host = UIHostingController(rootView: row)
        let size = host.sizeThatFits(in: CGSize(width: 280, height: CGFloat.greatestFiniteMagnitude))
        // Large type needs more than three lines for the full action, plus title and credits.
        XCTAssertGreaterThan(size.height, 400)
    }
    @MainActor
    func testNativeTextItemActionSelectsOnlyFeedbackReferences() throws {
        var selected: Int?
        let coordinator = AssessedTextView.Coordinator { selected = $0 }
        let button = UIButton()
        let action = try XCTUnwrap(coordinator.feedbackAction(for: URL(string: "artemis-feedback://2")))
        button.addAction(action, for: .primaryActionTriggered)
        button.sendActions(for: .primaryActionTriggered)
        XCTAssertEqual(selected, 2)
        XCTAssertNil(coordinator.feedbackAction(for: URL(string: "https://example.com/2")))
        XCTAssertNil(coordinator.feedbackAction(for: URL(string: "artemis-feedback://-1")))
        XCTAssertNotEqual(ReviewCopy.text("review.title"), "review.title")
    }
}
