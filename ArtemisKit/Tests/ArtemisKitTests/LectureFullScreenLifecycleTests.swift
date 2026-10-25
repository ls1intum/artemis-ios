import XCTest
@testable import CourseView

@MainActor
final class LectureFullScreenLifecycleTests: XCTestCase {
    func testFullscreenKeepsTheSamePlayerUntilActualViewerDeparture() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let snapshot = LectureMediaSession(account: "fullscreen-test", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString,
                                         snapshot: snapshot, isCurrent: { true })
        defer { model.stop() }
        model.viewDidAppear()
        await model.prepareIfNeeded()
        let original = try XCTUnwrap(model.player)
        model.beginFullScreenPresentation()
        model.viewDidDisappear() // AVKit temporarily covers the inline SwiftUI view.
        XCTAssertTrue(model.player === original)
        XCTAssertNotNil(original.currentItem)
        model.viewDidAppear()
        model.endFullScreenPresentation(inlineAttached: true)
        await model.prepareIfNeeded()
        XCTAssertTrue(model.player === original)
        model.viewDidDisappear() // Actual unit navigation/dismissal after fullscreen ends.
        XCTAssertNil(model.player)
        XCTAssertNil(original.currentItem)
    }

    func testEndingFullscreenAfterOwnerWasRemovedStopsThePlayer() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let snapshot = LectureMediaSession(account: "fullscreen-test", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString,
                                         snapshot: snapshot, isCurrent: { true })
        model.viewDidAppear()
        await model.load()
        model.beginFullScreenPresentation()
        model.viewDidDisappear()
        model.endFullScreenPresentation(inlineAttached: false)
        XCTAssertNil(model.player)
    }
}
