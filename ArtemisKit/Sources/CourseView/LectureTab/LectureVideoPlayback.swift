import AVKit
import Combine
import Foundation

@MainActor
final class LectureVideoPlayback: ObservableObject {
    enum State: Equatable { case loading, ready, failed(String) }
    @Published private(set) var state: State = .loading
    @Published private(set) var player: AVPlayer?
    private let source: URL
    private let snapshot: LectureMediaSession?
    private let progress: LectureMediaProgress?
    private let isCurrent: () -> Bool
    private var generation = LectureMediaLoadGeneration()
    private var activeLoadRequest: UUID?
    private var pauseRevision = UUID()
    private var fullScreenExitID: UUID?
    private var fullScreenExitIntent: FullScreenExitIntent?
    private let isActive: () -> Bool
    private let resumePlayback: (AVPlayer, Float) -> Void

    private struct FullScreenExitIntent {
        let player: AVPlayer
        let item: AVPlayerItem
        let request: UUID
        let pauseRevision: UUID
        let rate: Float
    }
    private var proxy: LectureMediaProxy?
    private var observation: NSKeyValueObservation?
    private var timeObserver: Any?
    private var failureObserver: NSObjectProtocol?
    private(set) var fullScreenPresented = false
    private var inlineVisible = false
    private var restored = false
    private var restorePending = false
    private let makeItem: (URL) -> AVPlayerItem
    private let seek: (AVPlayer, CMTime, @escaping (Bool) -> Void) -> Void
    private let preparationTimeout: Duration

    init(source: URL, identity: String, snapshot: LectureMediaSession? = .capture(), isCurrent: (() -> Bool)? = nil,
         makeItem: @escaping (URL) -> AVPlayerItem = { AVPlayerItem(url: $0) },
         seek: @escaping (AVPlayer, CMTime, @escaping (Bool) -> Void) -> Void = { player, time, completion in
             player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: completion)
         }, preparationTimeout: Duration = .seconds(40),
         isActive: @escaping () -> Bool = { UIApplication.shared.applicationState == .active },
         resumePlayback: @escaping (AVPlayer, Float) -> Void = { player, rate in player.rate = rate }) {
        self.isActive = isActive
        self.resumePlayback = resumePlayback
        self.makeItem = makeItem
        self.seek = seek
        self.preparationTimeout = preparationTimeout
        self.source = source
        self.snapshot = snapshot
        self.isCurrent = isCurrent ?? { snapshot?.isCurrent == true }
        progress = snapshot?.progress(identity: identity)
    }

    func load() async {
        stop()
        let request = generation.begin()
        activeLoadRequest = request
        state = .loading
        restored = false
        restorePending = false
        guard let snapshot, isCurrent() else { state = .failed(LectureMediaError.sessionChanged.localizedDescription); return }
        guard LectureMediaSource.classify(source) == .video else { state = .failed(LectureMediaError.invalidURL.localizedDescription); return }
        let isCurrent = self.isCurrent
        let proxy = LectureMediaProxy(policy: snapshot.policy, isCurrent: isCurrent)
        self.proxy = proxy
        do {
            let url = try await proxy.start(source: source)
            guard !Task.isCancelled, generation.accepts(request) else { proxy.stop(); return }
            guard isCurrent() else {
                proxy.stop()
                state = .failed(LectureMediaError.sessionChanged.localizedDescription)
                return
            }
            let item = makeItem(url)
            let player = AVPlayer(playerItem: item)
            player.allowsExternalPlayback = false // A remote receiver cannot access device loopback.
            player.preventsDisplaySleepDuringVideoPlayback = true
            self.player = player
            observation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                Task { @MainActor in
                    guard let self, self.generation.accepts(request), isCurrent() else { return }
                    switch item.status {
                    case .readyToPlay:
                        guard self.state == .loading, !self.restorePending else { return }
                        if !self.restored {
                            let duration = item.duration.seconds
                            if duration.isFinite, duration > 0, let seconds = self.progress?.seconds, seconds > 0 {
                                self.restorePending = true
                                self.seek(player, CMTime(seconds: min(seconds, max(0, duration - 1)), preferredTimescale: 600)) { [weak self, weak item] finished in
                                    Task { @MainActor in
                                        guard let self, let item, self.generation.accepts(request), isCurrent(),
                                              self.state == .loading, self.restorePending,
                                              self.player?.currentItem === item, item.status == .readyToPlay else { return }
                                        guard finished else { self.fail(); return }
                                        self.restorePending = false
                                        self.restored = true
                                        self.state = .ready
                                    }
                                }
                                return
                            }
                            self.restored = true
                        }
                        self.state = .ready
                    case .failed: self.fail()
                    default: break
                    }
                }
            }
            failureObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.generation.accepts(request), isCurrent() else { return }
                    self.fail()
                }
            }
            timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 2, preferredTimescale: 600), queue: .main) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    if isCurrent() { self.save() }
                    else { self.sessionChanged() }
                }
            }
            // Preparation has a recovery deadline. User playback can take as long as needed.
            let timeout = preparationTimeout
            Task { [weak self] in
                try? await Task.sleep(for: timeout)
                guard let self, self.generation.accepts(request), self.state == .loading else { return }
                self.fail()
            }
        } catch {
            guard generation.accepts(request), !Task.isCancelled else { return }
            state = .failed(isCurrent() ? LectureMediaError.unavailable.localizedDescription : LectureMediaError.sessionChanged.localizedDescription)
            proxy.stop()
        }
    }

    func prepareIfNeeded() async {
        guard player == nil else { return }
        await load()
    }
    func viewDidAppear() { inlineVisible = true }
    func viewDidDisappear() {
        inlineVisible = false
        if !fullScreenPresented { stop() }
    }
    func beginFullScreenPresentation() {
        fullScreenExitID = nil; fullScreenExitIntent = nil
        fullScreenPresented = true
    }
    func beginFullScreenExit() -> UUID {
        let transition = UUID()
        fullScreenExitID = transition
        fullScreenExitIntent = nil
        if fullScreenPresented, state == .ready, isCurrent(), isActive(),
           let player, let item = player.currentItem, item.status == .readyToPlay,
           player.rate.isFinite, player.rate > 0, let request = activeLoadRequest,
           generation.accepts(request) {
            fullScreenExitIntent = FullScreenExitIntent(player: player, item: item, request: request,
                                                       pauseRevision: pauseRevision, rate: player.rate)
        }
        return transition
    }
    func completeFullScreenExit(_ transition: UUID, cancelled: Bool, inlineAttached: Bool) {
        guard fullScreenExitID == transition else { return }
        let intent = fullScreenExitIntent
        fullScreenExitID = nil; fullScreenExitIntent = nil
        guard !cancelled else { return }
        endFullScreenPresentation(inlineAttached: inlineAttached)
        // AVKit pauses during native exit. Restore only the playing intent from
        // this transition; every app pause invalidates it, including background.
        guard let intent, state == .ready, isCurrent(), isActive(),
              inlineVisible || inlineAttached, generation.accepts(intent.request),
              pauseRevision == intent.pauseRevision, player === intent.player,
              intent.player.currentItem === intent.item, intent.item.status == .readyToPlay,
              intent.player.rate == 0 else { return }
        resumePlayback(intent.player, intent.rate)
    }
    func endFullScreenPresentation(inlineAttached: Bool) {
        fullScreenExitID = nil; fullScreenExitIntent = nil
        fullScreenPresented = false
        if !inlineVisible && !inlineAttached { stop() }
    }

    func pause() {
        pauseRevision = UUID(); fullScreenExitIntent = nil
        save(); player?.pause()
    }

    func stop() {
        fullScreenExitID = nil; fullScreenExitIntent = nil; activeLoadRequest = nil
        fullScreenPresented = false
        pause()
        generation.cancel()
        restorePending = false
        player?.currentItem?.cancelPendingSeeks()
        observation?.invalidate(); observation = nil
        if let timeObserver, let player { player.removeTimeObserver(timeObserver) }
        timeObserver = nil
        if let failureObserver { NotificationCenter.default.removeObserver(failureObserver) }
        failureObserver = nil
        player?.replaceCurrentItem(with: nil)
        player = nil
        proxy?.stop(); proxy = nil
    }

    func sessionChanged() {
        guard !isCurrent() else { return }
        stop()
        state = .failed(LectureMediaError.sessionChanged.localizedDescription)
    }

    private func save() {
        guard restored, let seconds = player?.currentTime().seconds else { return }
        progress?.save(seconds: seconds)
    }

    private func fail() {
        if case .failed = state { return }
        pause()
        // Failure is terminal for this generation, including a pending seek.
        generation.cancel()
        restorePending = false
        player?.currentItem?.cancelPendingSeeks()
        observation?.invalidate(); observation = nil
        if let timeObserver, let player { player.removeTimeObserver(timeObserver) }
        timeObserver = nil
        if let failureObserver { NotificationCenter.default.removeObserver(failureObserver) }
        failureObserver = nil
        state = .failed(LectureMediaError.unavailable.localizedDescription)
        proxy?.stop()
    }
}
