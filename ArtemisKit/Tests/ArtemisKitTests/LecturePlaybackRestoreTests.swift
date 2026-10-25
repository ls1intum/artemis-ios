import AVKit
import XCTest
@testable import CourseView

@MainActor
final class LecturePlaybackRestoreTests: XCTestCase {
    func testUnfinishedSeekCannotEnablePlaybackOrOverwriteSavedPosition() async throws {
        try await exerciseRestore(completion: false, failure: false, timeout: false)
    }
    func testSeekCompletionAfterFailureCannotRemoveRetry() async throws {
        try await exerciseRestore(completion: true, failure: true, timeout: false)
    }
    func testSeekCompletionAfterDeadlineCannotRemoveRetry() async throws {
        try await exerciseRestore(completion: true, failure: false, timeout: true)
    }

    private func exerciseRestore(completion finished: Bool, failure: Bool, timeout: Bool) async throws {
        let fixture = try await MediaHTTPFixture.start()
        defer { fixture.stop() }
        let snapshot = LectureMediaSession(account: "restore-test", origin: fixture.base, token: nil)
        let identity = UUID().uuidString
        snapshot.progress(identity: identity).save(seconds: 10)
        var completion: ((Bool) -> Void)?
        let model = LectureVideoPlayback(source: fixture.base.appending(path: "video.mp4"), identity: identity,
            snapshot: snapshot, isCurrent: { true }, makeItem: { ReadyMediaItem(url: $0) },
            seek: { _, _, callback in completion = callback }, preparationTimeout: timeout ? .milliseconds(20) : .seconds(40))
        defer { model.stop() }
        await model.load()
        for _ in 0..<100 where completion == nil { await Task.yield() }
        let callback = try XCTUnwrap(completion)
        if failure {
            NotificationCenter.default.post(name: .AVPlayerItemFailedToPlayToEndTime, object: model.player?.currentItem)
            for _ in 0..<20 { await Task.yield() }
        }
        if timeout { try await Task.sleep(for: .milliseconds(80)) }
        callback(finished)
        for _ in 0..<20 { await Task.yield() }
        if case .failed = model.state {} else { XCTFail("A failed or unfinished restore must retain Retry") }
        XCTAssertEqual(snapshot.progress(identity: identity).seconds, 10)
    }
}

private final class ReadyMediaItem: AVPlayerItem {
    override var status: AVPlayerItem.Status { .readyToPlay }
    override var duration: CMTime { CMTime(seconds: 48, preferredTimescale: 600) }
}
