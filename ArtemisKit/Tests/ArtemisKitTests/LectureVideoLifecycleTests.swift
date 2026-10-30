import AVKit
import XCTest
@testable import CourseView

@MainActor
final class LectureVideoLifecycleTests: XCTestCase {
    func testPreparationDoesNotAutoplayAndClosingReleasesTheItem() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let snapshot = LectureMediaSession(account: "test", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString, snapshot: snapshot, isCurrent: { true })
        await model.load()
        let player = try XCTUnwrap(model.player)
        XCTAssertEqual(player.rate, 0)
        model.stop()
        XCTAssertNil(model.player)
        XCTAssertNil(player.currentItem)
    }

    func testLateFailureFromPreviousItemCannotCancelARetry() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let snapshot = LectureMediaSession(account: "test", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString, snapshot: snapshot, isCurrent: { true })
        defer { model.stop() }
        await model.load()
        let oldItem = try XCTUnwrap(model.player?.currentItem)
        // Queue the old notification's main-actor work just before retry yields.
        NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: oldItem)
        await model.load()
        XCTAssertNotNil(model.player)
        XCTAssertEqual(model.state, .loading)
    }

    func testFailedMediaCanCreateANewPausedPlayerOnRetry() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let snapshot = LectureMediaSession(account: "test", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString, snapshot: snapshot, isCurrent: { true })
        defer { model.stop() }
        await model.load()
        for _ in 0..<100 {
            if case .failed = model.state { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        guard case .failed = model.state else { XCTFail("Invalid media must produce a recoverable failure"); return }
        let oldPlayer = model.player
        await model.load()
        XCTAssertNotNil(model.player)
        XCTAssertNotIdentical(model.player, oldPlayer)
        XCTAssertEqual(model.player?.rate, 0)
        XCTAssertNil(oldPlayer?.currentItem)
    }

    func testSessionChangeCancelsPlayerAndLatePreparation() async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        var current = true
        let snapshot = LectureMediaSession(account: "test", origin: fixture.base, token: nil)
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: UUID().uuidString, snapshot: snapshot, isCurrent: { current })
        let loading = Task { await model.load() }
        await Task.yield()
        current = false
        model.sessionChanged()
        await loading.value
        XCTAssertNil(model.player)
        if case .failed = model.state {} else { XCTFail("A changed session must be visible as an error") }
        model.stop()
    }
}
