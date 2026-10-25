import Common
import XCTest
@testable import Messages

@MainActor
final class MessageUploadPresentationTests: XCTestCase {
    func testPickerDismissalCannotResetAnImageUploadInProgress() {
        let model = SendMessageUploadImageViewModel(courseId: 1, conversationId: 2)
        for state: UploadState in [.compressing, .uploading] {
            model.uploadState = state
            XCTAssertTrue(model.showUploadScreen.wrappedValue)
            // Photos and the progress sheet have different presenters. SwiftUI can write
            // false during that transition before the upload's result arrives.
            model.showUploadScreen.wrappedValue = false
            XCTAssertEqual(model.uploadState, state)
            XCTAssertTrue(model.showUploadScreen.wrappedValue)
        }
    }

    func testTerminalDismissalRetainsTheUploadedPathUntilInsertion() {
        let model = SendMessageUploadImageViewModel(courseId: 1, conversationId: 2)
        model.filePath = "/api/files/image.jpg"
        model.uploadState = .done
        model.showUploadScreen.wrappedValue = false
        XCTAssertEqual(model.uploadState, .idle)
        XCTAssertEqual(model.filePath, "/api/files/image.jpg")
        XCTAssertFalse(model.showUploadScreen.wrappedValue)
    }

    func testExplicitCancellationClosesTheScreenAndClearsTheUpload() {
        let model = SendMessageUploadImageViewModel(courseId: 1, conversationId: 2)
        model.uploadState = .uploading
        model.filePath = "/api/files/stale.jpg"
        model.cancel()
        XCTAssertFalse(model.showUploadScreen.wrappedValue)
        XCTAssertNil(model.filePath)
        XCTAssertEqual(model.uploadState, .idle)
    }
}
