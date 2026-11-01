import SwiftUI
import WebKit

struct ModelReviewCanvas: View {
    @Environment(\.colorScheme) private var colorScheme
    let model: String
    let diagramType: String?
    let feedback: [StudentFeedback]
    let selectedReference: String?
    let onSelect: (String) -> Void
    @State private var failure: String?

    var body: some View {
        if let failure {
            ContentUnavailableView(ReviewCopy.text("review.modelUnavailable"), systemImage: "square.3.layers.3d", description: Text(failure))
        } else {
            ModelCanvasWebView(model: model, diagramType: diagramType, feedback: feedback,
                               selectedReference: selectedReference, darkMode: colorScheme == .dark,
                               failure: $failure, onSelect: onSelect)
                .accessibilityLabel(ReviewCopy.text("review.assessedDiagram"))
        }
    }
}

private struct ModelCanvasWebView: UIViewRepresentable {
    let model: String
    let diagramType: String?
    let feedback: [StudentFeedback]
    let selectedReference: String?
    let darkMode: Bool
    @Binding var failure: String?
    let onSelect: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        for name in ["modelSelection", "modelReady", "modelError"] { configuration.userContentController.add(context.coordinator, name: name) }
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.isInspectable = false
        view.allowsLinkPreview = false
        view.isOpaque = false
        context.coordinator.webView = view
        guard let file = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "ModelReview") else {
            DispatchQueue.main.async { failure = ReviewCopy.text("review.modelUnavailable") }
            return view
        }
        context.coordinator.directory = file.deletingLastPathComponent()
        view.loadFileURL(file, allowingReadAccessTo: file.deletingLastPathComponent())
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.render()
    }
    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
        view.stopLoading()
        for name in ["modelSelection", "modelReady", "modelError"] { view.configuration.userContentController.removeScriptMessageHandler(forName: name) }
        view.loadHTMLString("", baseURL: nil)
        view.navigationDelegate = nil
    }
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: ModelCanvasWebView
        weak var webView: WKWebView?
        var directory: URL?
        var ready = false
        var previous: String?
        init(parent: ModelCanvasWebView) { self.parent = parent }
        func render() {
            guard ready, let webView else { return }
            do {
                let model = try JSONSerialization.jsonObject(with: Data(parent.model.utf8))
                let feedback: [[String: Any]] = parent.feedback.map { item in
                    var publicItem: [String: Any] = ["detailText": item.message]
                    if let reference = item.reference { publicItem["reference"] = reference }
                    if let credits = item.credits { publicItem["credits"] = credits }
                    if let positive = item.positive { publicItem["positive"] = positive }
                    return publicItem
                }
                let payload: [String: Any] = ["model": model, "diagramType": parent.diagramType ?? "ClassDiagram",
                                              "feedback": feedback, "selectedReference": parent.selectedReference as Any? ?? NSNull(), "darkMode": parent.darkMode]
                let base64 = try JSONSerialization.data(withJSONObject: payload, options: .sortedKeys).base64EncodedString()
                guard previous != base64 else { return }
                previous = base64
                webView.evaluateJavaScript("window.ArtemisModelReview.renderBase64('\(base64)')") { [weak self] value, error in
                    if error != nil || (value as? [String: Any])?["ok"] as? Bool == false { self?.parent.failure = ReviewCopy.text("review.modelUnavailable") }
                }
            } catch { parent.failure = ReviewCopy.text("review.modelUnavailable") }
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("window.ArtemisModelReview?.isReady === true") { [weak self] value, _ in
                if value as? Bool == true { self?.ready = true; self?.render() }
            }
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url, url.isFileURL, let directory,
                  url.standardizedFileURL.path.hasPrefix(directory.standardizedFileURL.path + "/") else { decisionHandler(.cancel); return }
            decisionHandler(.allow)
        }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame else { return }
            switch message.name {
            case "modelReady": ready = true; render()
            case "modelError": parent.failure = ReviewCopy.text("review.modelUnavailable")
            case "modelSelection":
                if let reference = (message.body as? [String: Any])?["reference"] as? String { parent.onSelect(reference) }
            default: break
            }
        }
    }
}
