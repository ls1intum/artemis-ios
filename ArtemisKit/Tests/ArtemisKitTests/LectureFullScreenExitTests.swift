import AVKit
import XCTest
@testable import CourseView

@MainActor
final class LectureFullScreenExitTests: XCTestCase {
    func testSuccessfulExitRestoresThePriorPlayingRateOnlyOnceAndReopensPaused() async throws {
        try await exercise { model, player, environment in
            player.rate = 1.5
            XCTAssertEqual(player.rate, 1.5)
            let transition = model.beginFullScreenExit()
            player.pause() // AVKit's observed pause during its exit animation.
            model.completeFullScreenExit(transition, cancelled: false, inlineAttached: true)
            XCTAssertEqual(player.rate, 1.5)
            XCTAssertEqual(environment.resumes, [1.5])
            model.pause()
            model.completeFullScreenExit(transition, cancelled: false, inlineAttached: true)
            XCTAssertEqual(player.rate, 0, "An old completion cannot replay after a later pause")
            model.viewDidDisappear()
            await model.prepareIfNeeded()
            XCTAssertEqual(model.player?.rate, 0, "Reopening still requires the user to play")
            XCTAssertEqual(environment.resumes, [1.5])
        }
    }

    func testUserPausedAndAlreadyPlayingExitsDoNotIssuePlayCommands() async throws {
        try await exercise { model, player, environment in
            let paused = model.beginFullScreenExit()
            model.completeFullScreenExit(paused, cancelled: false, inlineAttached: true)
            XCTAssertEqual(player.rate, 0)
            model.beginFullScreenPresentation()
            player.rate = 1.5
            let playing = model.beginFullScreenExit()
            model.completeFullScreenExit(playing, cancelled: false, inlineAttached: true)
            XCTAssertEqual(player.rate, 1.5)
            XCTAssertTrue(environment.resumes.isEmpty)
        }
    }

    func testCancelledAndSupersededTransitionsCannotResume() async throws {
        try await exercise { model, player, environment in
            player.rate = 1
            let cancelled = model.beginFullScreenExit()
            player.pause()
            model.completeFullScreenExit(cancelled, cancelled: true, inlineAttached: true)
            XCTAssertTrue(model.fullScreenPresented)
            XCTAssertEqual(player.rate, 0)
            player.rate = 1
            let superseded = model.beginFullScreenExit()
            model.beginFullScreenPresentation()
            player.pause()
            model.completeFullScreenExit(superseded, cancelled: false, inlineAttached: true)
            XCTAssertTrue(model.fullScreenPresented)
            XCTAssertEqual(player.rate, 0)
            XCTAssertTrue(environment.resumes.isEmpty)
        }
    }

    func testOwnerPauseDuringExitInvalidatesPlayingIntent() async throws {
        try await exercise { model, player, environment in
            player.rate = 1
            let transition = model.beginFullScreenExit()
            model.pause() // Background, interruption, or an explicit app pause.
            model.completeFullScreenExit(transition, cancelled: false, inlineAttached: true)
            XCTAssertFalse(model.fullScreenPresented)
            XCTAssertEqual(player.rate, 0)
            XCTAssertTrue(environment.resumes.isEmpty)
        }
    }

    func testInactiveAppCannotResumeEvenBeforePauseNotificationArrives() async throws {
        try await exercise { model, player, environment in
            player.rate = 1
            let transition = model.beginFullScreenExit()
            player.pause()
            environment.active = false
            model.completeFullScreenExit(transition, cancelled: false, inlineAttached: true)
            environment.active = true
            model.completeFullScreenExit(transition, cancelled: false, inlineAttached: true)
            XCTAssertEqual(player.rate, 0)
            XCTAssertTrue(environment.resumes.isEmpty)
        }
    }

    func testSessionChangeAndReplacedPlayerCannotResume() async throws {
        try await exercise { model, player, environment in
            player.rate = 1
            let sessionExit = model.beginFullScreenExit()
            environment.current = false
            model.sessionChanged()
            model.completeFullScreenExit(sessionExit, cancelled: false, inlineAttached: true)
            XCTAssertNil(model.player)
            environment.current = true
            await model.load()
            model.beginFullScreenPresentation()
            let replacement = try XCTUnwrap(model.player)
            replacement.rate = 1
            let replacedExit = model.beginFullScreenExit()
            await model.load()
            model.completeFullScreenExit(replacedExit, cancelled: false, inlineAttached: true)
            XCTAssertFalse(model.player === replacement)
            XCTAssertEqual(model.player?.rate, 0)
            XCTAssertTrue(environment.resumes.isEmpty)
        }
    }

    func testReplacedItemCannotReceiveOldPlayingIntent() async throws {
        try await exercise { model, player, environment in
            player.rate = 1
            let transition = model.beginFullScreenExit()
            let url = try XCTUnwrap((player.currentItem?.asset as? AVURLAsset)?.url)
            let replacement = FullscreenReadyItem(url: url)
            player.replaceCurrentItem(with: replacement)
            player.pause()
            model.completeFullScreenExit(transition, cancelled: false, inlineAttached: true)
            XCTAssertTrue(player.currentItem === replacement)
            XCTAssertEqual(player.rate, 0)
            XCTAssertTrue(environment.resumes.isEmpty)
        }
    }

    func testActualOwnerDepartureStopsInsteadOfResuming() async throws {
        try await exercise { model, player, environment in
            player.rate = 1
            let transition = model.beginFullScreenExit()
            model.viewDidDisappear()
            player.pause()
            model.completeFullScreenExit(transition, cancelled: false, inlineAttached: false)
            XCTAssertNil(model.player)
            XCTAssertNil(player.currentItem)
            XCTAssertTrue(environment.resumes.isEmpty)
        }
    }

    func testFailureDuringExitCannotResume() async throws {
        try await exercise { model, player, environment in
            player.rate = 1
            let transition = model.beginFullScreenExit()
            NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: player.currentItem)
            for _ in 0..<20 { await Task.yield() }
            model.completeFullScreenExit(transition, cancelled: false, inlineAttached: true)
            if case .failed = model.state {} else { XCTFail("Failure must remain terminal") }
            XCTAssertEqual(player.rate, 0)
            XCTAssertTrue(environment.resumes.isEmpty)
        }
    }

    private func exercise(_ body: @MainActor (LectureVideoPlayback, AVPlayer, ExitEnvironment) async throws -> Void) async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let environment = ExitEnvironment()
        let snapshot = LectureMediaSession(account: "fullscreen-exit", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString,
            snapshot: snapshot, isCurrent: { environment.current }, makeItem: { FullscreenReadyItem(url: $0) },
            isActive: { environment.active }, resumePlayback: { player, rate in environment.resumes.append(rate); player.rate = rate })
        defer { model.stop() }
        model.viewDidAppear()
        await model.load()
        for _ in 0..<100 where model.state != .ready { await Task.yield() }
        XCTAssertEqual(model.state, .ready)
        model.beginFullScreenPresentation()
        try await body(model, XCTUnwrap(model.player), environment)
    }
}

private final class ExitEnvironment {
    var current = true
    var active = true
    var resumes: [Float] = []
}

private final class FullscreenReadyItem: AVPlayerItem {
    override var status: AVPlayerItem.Status { .readyToPlay }
    override var duration: CMTime { CMTime(seconds: 48, preferredTimescale: 600) }
}
