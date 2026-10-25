import WebKit
import XCTest
@testable import CourseView

@MainActor
final class LectureProviderPlaybackTests: XCTestCase {
    func testDisappearanceAndInterruptionPauseTheAttachedWebPlayer() {
        let controller = LectureProviderPlayback()
        let view = RecordingProviderView()
        controller.attach(view)
        controller.pause()
        controller.pause()
        XCTAssertEqual(view.pauses, 2)
    }

    func testRetiringOldWebViewCannotDetachTheNewPlayer() {
        let controller = LectureProviderPlayback()
        let old = RecordingProviderView()
        let current = RecordingProviderView()
        controller.attach(old)
        controller.attach(current)
        controller.detach(old)
        controller.pause()
        XCTAssertGreaterThan(old.pauses, 0)
        XCTAssertEqual(current.pauses, 1)
    }
}

private final class RecordingProviderView: WKWebView {
    var pauses = 0
    override func pauseAllMediaPlayback(completionHandler: (() -> Void)? = nil) {
        pauses += 1
        completionHandler?()
    }
}
