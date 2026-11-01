import AVKit
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
        XCTAssertIdentical(model.player, original)
        XCTAssertNotNil(original.currentItem)
        model.viewDidAppear()
        model.endFullScreenPresentation(inlineAttached: true)
        await model.prepareIfNeeded()
        XCTAssertIdentical(model.player, original)
        model.viewDidDisappear() // Actual unit navigation/dismissal after fullscreen ends.
        XCTAssertNil(model.player)
        XCTAssertNil(original.currentItem)
    }

    func testRetiredInlineControllerDoesNotPauseSharedPlayerAfterFullscreenEnds() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let snapshot = LectureMediaSession(account: "fullscreen-retire", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString,
                                         snapshot: snapshot, isCurrent: { true })
        defer { model.stop() }
        model.viewDidAppear()
        await model.load()
        let player = try XCTUnwrap(model.player)
        let retired = AVPlayerViewController()
        retired.player = player
        model.beginFullScreenPresentation()
        model.viewDidDisappear()
        model.viewDidAppear()
        model.endFullScreenPresentation(inlineAttached: true)
        player.play()
        XCTAssertEqual(player.rate, 1)
        LectureVideoPlayer.dismantleUIViewController(retired, coordinator: .init(model))
        XCTAssertIdentical(model.player, player)
        XCTAssertEqual(player.rate, 1, "Only the playback owner may pause the shared player")
        XCTAssertNil(retired.player)
        player.pause()
        let paused = AVPlayerViewController()
        paused.player = player
        LectureVideoPlayer.dismantleUIViewController(paused, coordinator: .init(model))
        XCTAssertEqual(player.rate, 0, "Retiring a controller must also preserve the user’s pause")
        model.viewDidDisappear()
        XCTAssertNil(model.player)
        XCTAssertNil(player.currentItem)
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
