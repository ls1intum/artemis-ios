import XCTest
@testable import Messages

final class MessageComposerResizeTests: XCTestCase {
    func testDragFollowsTheFingerWithoutAccumulatingTranslations() {
        var resize = MessageComposerResizeState()
        resize.update(translation: -80, maximum: 240)
        XCTAssertEqual(resize.extraHeight, 80)
        resize.update(translation: -120, maximum: 240)
        XCTAssertEqual(resize.extraHeight, 120)
    }

    func testDraggingClampsAtBothEnds() {
        var resize = MessageComposerResizeState()
        resize.update(translation: -900, maximum: 240)
        XCTAssertEqual(resize.extraHeight, 240)
        resize.update(translation: 900, maximum: 240)
        XCTAssertEqual(resize.extraHeight, 0)
    }

    func testDownwardDragCollapsesAfterRotatingIntoASmallerWindow() {
        var resize = MessageComposerResizeState()
        resize.setExpanded(true, maximum: 240)
        resize.update(translation: 90, maximum: 120)
        XCTAssertEqual(resize.extraHeight, 30)
        resize.finish(translation: 90, maximum: 120)
        XCTAssertEqual(resize.extraHeight, 0)
        resize.update(translation: -60, maximum: 120)
        resize.finish(translation: -60, maximum: 120)
        XCTAssertEqual(resize.extraHeight, 120)
    }

    func testSmallDragsReturnToTheNearestSize() {
        var resize = MessageComposerResizeState()
        resize.update(translation: -10, maximum: 240)
        resize.finish(translation: -10, maximum: 240)
        XCTAssertEqual(resize.extraHeight, 0)
        resize.setExpanded(true, maximum: 240)
        resize.update(translation: 20, maximum: 240)
        resize.finish(translation: 20, maximum: 240)
        XCTAssertEqual(resize.extraHeight, 240)
    }

    func testInterruptedDragUsesTheVisibleHeightAsItsNextStartingPoint() {
        var resize = MessageComposerResizeState()
        resize.update(translation: -100, maximum: 240)
        resize.cancelGesture()
        resize.update(translation: -20, maximum: 240)
        XCTAssertEqual(resize.extraHeight, 120)
    }

    func testHorizontalReleaseDoesNotSwitchSizes() {
        var resize = MessageComposerResizeState()
        resize.finish(translation: -25, horizontalTranslation: 100, maximum: 240)
        XCTAssertEqual(resize.extraHeight, 0)
        resize.setExpanded(true, maximum: 240)
        resize.finish(translation: 25, horizontalTranslation: 100, maximum: 240)
        XCTAssertEqual(resize.extraHeight, 240)
    }
}
