import AVKit
import SwiftUI
import XCTest
@testable import CourseView

@MainActor
final class LectureVideoPageTests: XCTestCase {
    func testNativePlayerEntersFullscreenOnPlayAndUsesThePageBounds() async throws {
        let playback = LectureVideoPlayback(source: URL(string: "https://example.org/lecture.mp4")!, identity: "page-test")
        let host = UIHostingController(rootView: LectureVideoPlayer(player: AVPlayer(), playback: playback))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1100, height: 800))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        for _ in 0..<100 where findPlayer(in: host) == nil { try await Task.sleep(for: .milliseconds(10)) }
        let player = try XCTUnwrap(findPlayer(in: host))
        XCTAssertTrue(player.entersFullScreenWhenPlaybackBegins, "The native Play button should enter fullscreen directly")
        XCTAssertTrue(player.showsPlaybackControls)
        XCTAssertEqual(player.view.bounds.width, host.view.bounds.width, accuracy: 1)
        XCTAssertGreaterThan(player.view.bounds.height, host.view.bounds.height * 0.8)
    }

    private func findPlayer(in controller: UIViewController) -> AVPlayerViewController? {
        if let player = controller as? AVPlayerViewController { return player }
        return controller.children.lazy.compactMap { self.findPlayer(in: $0) }.first
    }
}
