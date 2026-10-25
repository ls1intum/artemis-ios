import AVKit
import DesignLibrary
import SharedModels
import SwiftUI
import UserStore
import WebKit

struct VideoUnitSheetContent: View {
    let unit: AttachmentVideoUnit
    let videoSource: URL
    let identity: String
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var session = UserSessionFactory.shared
    @StateObject private var playback: LectureVideoPlayback
    @State private var snapshot = LectureMediaSession.capture()
    @State private var sessionValid = true

    init(unit: AttachmentVideoUnit, videoSource: URL, identity: String) {
        self.unit = unit
        self.videoSource = videoSource
        self.identity = identity
        _playback = StateObject(wrappedValue: LectureVideoPlayback(source: videoSource, identity: identity))
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 12) {
                Group {
                    if !sessionValid {
                        Text(LectureMediaError.sessionChanged.localizedDescription).padding()
                    } else if LectureMediaSource.classify(videoSource) == .video {
                        ZStack {
                            if let player = playback.player { LectureVideoPlayer(player: player) }
                            switch playback.state {
                            case .loading:
                                ProgressView("Loading video…")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(.background)
                            case .failed(let message):
                                ContentUnavailableView {
                                    Label("Video could not be played", systemImage: "video.slash")
                                } description: {
                                    Text(message)
                                } actions: {
                                    Button("Retry") { Task { await playback.load() } }
                                }
                                .background(.background)
                            case .ready: EmptyView()
                            }
                        }
                    } else {
                        LectureProviderContent(url: videoSource, active: scenePhase == .active)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: max(180, min(proxy.size.height * 0.72, proxy.size.width * 9 / 16)))

                if sessionValid {
                    Link(destination: videoSource) { Label("Open in browser", systemImage: "safari") }
                        .buttonStyle(ArtemisButton())
                        .padding(.horizontal)
                }

                if let description = unit.description, !description.isEmpty {
                    ScrollView {
                        Text(description)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .task {
            if LectureMediaSource.classify(videoSource) == .video { await playback.load() }
        }
        .onDisappear { playback.stop() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { playback.pause() } }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in playback.pause() }
        .onReceive(session.objectWillChange) { _ in
            Task { @MainActor in
                await Task.yield()
                playback.sessionChanged()
                sessionValid = snapshot?.isCurrent == true
            }
        }
    }
}

private struct LectureVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.videoGravity = .resizeAspect
        controller.allowsPictureInPicturePlayback = false
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        return controller
    }
    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player { controller.player = player }
    }
    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: ()) {
        controller.player?.pause()
        controller.player = nil
    }
}

/// A separate, ephemeral website store never receives Artemis cookies. The fixed
/// viewport remains usable even when a provider blocks embedding or requires login.
private struct LectureProviderContent: View {
    let url: URL
    let active: Bool
    @State private var loading = true
    @State private var failed = false
    @State private var attempt = UUID()

    var body: some View {
        ZStack {
            LectureProviderPlayer(url: url, active: active, loading: $loading, failed: $failed).id(attempt)
            if loading { ProgressView("Loading provider…") }
            if failed {
                VStack(spacing: 12) {
                    Label("Provider could not be opened", systemImage: "network.slash").font(.headline)
                    Text("Try again, or use Open in browser if this provider requires a separate login.")
                        .font(.callout).multilineTextAlignment(.center)
                    Button("Retry") { loading = true; failed = false; attempt = UUID() }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background)
            }
        }
    }
}

private struct LectureProviderPlayer: UIViewRepresentable {
    let url: URL
    let active: Bool
    @Binding var loading: Bool
    @Binding var failed: Bool
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.load(URLRequest(url: url))
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {
        context.coordinator.parent = self
        if !active { view.pauseAllMediaPlayback() }
    }
    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
        view.pauseAllMediaPlayback()
        view.stopLoading()
        view.loadHTMLString("", baseURL: nil)
    }
    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: LectureProviderPlayer
        init(_ parent: LectureProviderPlayer) { self.parent = parent }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { parent.loading = false }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.loading = false; parent.failed = true
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.loading = false; parent.failed = true
        }
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { parent.loading = false; parent.failed = true }
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url, LectureMediaSource.classify(url) != .invalid else { decisionHandler(.cancel); return }
            if action.targetFrame == nil { webView.load(action.request); decisionHandler(.cancel) }
            else { decisionHandler(.allow) }
        }
    }
}
