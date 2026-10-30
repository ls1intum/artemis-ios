import UIKit
import XCTest

@MainActor
func makeTestWindow(frame: CGRect, file: StaticString = #filePath, line: UInt = #line) throws -> UIWindow {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = try XCTUnwrap(
        scenes.first(where: { $0.windows.contains(where: \.isKeyWindow) })
            ?? scenes.first(where: { $0.activationState == .foregroundActive })
            ?? scenes.first,
        "Native hosting tests require a test runner with a connected window scene.", file: file, line: line)
    let window = UIWindow(windowScene: scene)
    window.frame = frame
    return window
}
