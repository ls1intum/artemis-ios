import SwiftUI
import WebKit
import XCTest
@testable import CourseView

@MainActor
final class ModelReviewLifecycleTests: XCTestCase {
    func testDiagramKeepsItsNativeCanvasAcrossAdaptiveLayoutChanges() async throws {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: Self.self)
        #endif
        let name = "qa-modeling-submissions-with-results"
        let fixture = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures/StudentQA") ?? bundle.url(forResource: name, withExtension: "json"))
        let submissions = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: fixture)) as? [[String: Any]])
        let model = try XCTUnwrap(submissions.first?["model"] as? String)
        let layout = ModelReviewLayout()
        let host = UIHostingController(rootView: ModelReviewHarness(layout: layout, model: model))
        host.safeAreaRegions = []
        let window = try makeTestWindow(frame: CGRect(x: 0, y: 0, width: 790, height: 900))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        host.view.layoutIfNeeded()
        let portrait = try await renderedCanvas(in: host.view)
        for wide in [true, false, true, false] {
            layout.wide = wide
            layout.section = 1
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            let mounted = try await renderedCanvas(in: host.view)
            XCTAssertIdentical(portrait, mounted, "Rotating and switching sections must preserve the rendered native canvas")
            layout.section = 0
        }
    }

    private func renderedCanvas(in root: UIView) async throws -> WKWebView {
        for _ in 0..<150 {
            if let canvas = findCanvas(in: root),
               let count = try? await canvas.evaluateJavaScript("document.querySelectorAll('.react-flow__node').length") as? Int,
               count > 0 { return canvas }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTFail("The mounted canvas did not render the assessed model")
        throw NSError(domain: "ModelReviewLifecycleTests", code: 1)
    }

    private func findCanvas(in view: UIView) -> WKWebView? {
        if let canvas = view as? WKWebView { return canvas }
        return view.subviews.lazy.compactMap { self.findCanvas(in: $0) }.first
    }
}

@MainActor
private final class ModelReviewLayout: ObservableObject {
    @Published var wide = false
    @Published var section = 0
}

private struct ModelReviewHarness: View {
    @ObservedObject var layout: ModelReviewLayout
    let model: String
    var body: some View {
        ReviewModelPanes(wide: layout.wide, feedbackWidth: 250, section: $layout.section) {
            work
        } feedback: {
            Text("Feedback")
        }
    }
    private var work: some View {
        ScrollView {
            VStack {
                ModelReviewCanvas(model: model, diagramType: "ClassDiagram", feedback: [], selectedReference: nil) { _ in }
                    .frame(minHeight: 460)
                Text("Assessed explanation")
            }.padding()
        }
    }
}
