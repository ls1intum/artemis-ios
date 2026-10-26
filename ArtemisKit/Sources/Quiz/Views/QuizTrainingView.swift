import ReviewContent
import SwiftUI
import UserStore

public struct QuizTrainingView: View {
    private let courseId: Int
    private let scorePrecision: Int
    public static var title: String { TrainingCopy.text("title") }
    public init(courseId: Int) { self.init(courseId: courseId, scorePrecision: 1) }
    public init(courseId: Int, scorePrecision: Int) { self.courseId = courseId; self.scorePrecision = scorePrecision }
    public var body: some View { TrainingFeatureView(courseId: courseId, scorePrecision: scorePrecision).id(courseId) }
}

struct TrainingFeatureView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var account: UserSession
    @State private var model: QuizTrainingViewModel
    @State private var overview: TrainingOverview?
    @State private var showingQuestions = false
    @State private var transport: TrainingTransport?
    @State private var assets: ReviewAssetContext?

    init(courseId: Int, scorePrecision: Int, account: UserSession = UserSessionFactory.shared, token: (() -> String?)? = nil, makeTransport: ((TrainingIdentity) -> TrainingTransport)? = nil) {
        _account = ObservedObject(wrappedValue: account)
        let transport = TrainingIdentity.current(courseID: courseId, user: account, token: token).map { captured in
            makeTransport?(captured) ?? TrainingTransport(captured: captured, current: { TrainingIdentity.current(courseID: courseId, user: account, token: token) })
        }
        _transport = State(initialValue: transport)
        let model = QuizTrainingViewModel(courseId: courseId, transport: transport, scorePrecision: scorePrecision)
        let overview = transport.map { TrainingOverview(transport: $0) }
        _model = State(initialValue: model)
        _overview = State(initialValue: overview)
        _assets = State(initialValue: transport.map { captured in
            ReviewAssetContext(baseURL: captured.captured.baseURL, isCurrent: { captured.isCurrent }, load: { try await captured.assetData($0) }, didFail: { [weak model, weak overview] _ in
                Task { @MainActor in
                    if !captured.isCurrent { model?.loseAccess(); overview?.clear() }
                }
            })
        })
    }
    var body: some View {
        List {
            Section {
                Text(TrainingCopy.text("intro")).foregroundStyle(.secondary)
                Button { showingQuestions = true } label: {
                    Label(TrainingCopy.text(model.hasActiveSession ? "resume" : "start"), systemImage: "dumbbell.fill")
                        .font(.headline).padding(.vertical, 8)
                }
                .disabled(model.phase == .accessLost || transport == nil)
            }
            if let overview {
                TrainingOverviewSections(overview: overview)
            } else {
                Text(TrainingCopy.text("access.info"))
            }
        }
        .navigationTitle(QuizTrainingView.title)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showingQuestions) {
            QuizTraingQuestionsView(viewModel: model).environment(\.reviewAssets, assets)
        }
        .task {
            if overview?.data == nil { await overview?.load() } else { await overview?.refreshIfNeeded(after: model.progressRevision) }
        }
        .onChange(of: showingQuestions) { _, showing in
            if !showing { Task { await overview?.refreshIfNeeded(after: model.progressRevision) } }
        }
        .refreshable { await overview?.load() }
        .onReceive(account.$isLoggedIn) { if !$0 { clearAccess() } }
        .onChange(of: account.username) { _, _ in validate() }
        .onReceive(account.$institution) { if $0?.baseURL != transport?.captured.baseURL { clearAccess() } }
        .onChange(of: scenePhase) { _, phase in if phase == .active { validate() } }
    }
    private func clearAccess() { model.loseAccess(); overview?.clear(); transport?.invalidate() }
    private func validate() {
        model.validateSession()
        if transport?.isCurrent != true { overview?.clear(); transport?.invalidate() }
    }
}

private struct TrainingOverviewSections: View {
    @Bindable var overview: TrainingOverview
    var body: some View {
        if let entry = overview.data?.currentUserEntry {
            Section(TrainingCopy.text("progress")) {
                if let points = entry.score { LabeledContent(TrainingCopy.text("points"), value: points.formatted()) }
                if let correct = entry.answeredCorrectly { LabeledContent(TrainingCopy.text("progress.correct"), value: correct.formatted()) }
                if let wrong = entry.answeredWrong { LabeledContent(TrainingCopy.text("progress.wrong"), value: wrong.formatted()) }
                if let total = entry.totalQuestions { LabeledContent(TrainingCopy.text("progress.total"), value: total.formatted()) }
                if let streak = entry.streak { LabeledContent(TrainingCopy.text("streak"), value: streak.formatted()) }
                if let rank = overview.currentRank { LabeledContent(TrainingCopy.text("rank.current"), value: "#\(rank)") }
            }
        }
        Section(TrainingCopy.text("league")) {
            if let league = TrainingLeague(selectedLeague: overview.data?.currentUserEntry?.selectedLeague) {
                Text(league.name).font(.headline)
                Text(league.threshold).foregroundStyle(.secondary)
                if let score = overview.data?.currentUserEntry?.score, let upper = league.upperBound {
                    ProgressView(value: Double(min(upper - league.lowerBound, max(0, score - league.lowerBound))), total: Double(upper - league.lowerBound))
                    Text(String(format: TrainingCopy.text("league.next"), upper)).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            NavigationLink { TrainingLeagueInfoView() } label: { Label(TrainingCopy.text("league.info"), systemImage: "info.circle") }
        }
        Section(TrainingCopy.text("privacy.title")) {
            if overview.needsPrivacyChoice {
                Text(TrainingCopy.text("privacy.info")).foregroundStyle(.secondary)
                Button(TrainingCopy.text("privacy.private")) { Task { await overview.setVisibility(false) } }
                Button(TrainingCopy.text("privacy.public")) { Task { await overview.setVisibility(true) } }
            } else {
                Toggle(TrainingCopy.text("privacy.toggle"), isOn: Binding(get: { overview.visibility == true }, set: { visible in
                    Task { await overview.setVisibility(visible) }
                }))
            }
            if overview.failed {
                Text(TrainingCopy.text("privacy.error")).foregroundStyle(.secondary)
                Button(TrainingCopy.text("retry")) { Task { await overview.load() } }
            }
            if overview.busy { ProgressView() }
        }
        .disabled(overview.busy)
        if let entries = overview.data?.leaderboardEntries, !entries.isEmpty {
            Section(TrainingCopy.text("leaderboard")) {
                ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                    HStack(alignment: .firstTextBaseline) {
                        if let rank = entry.rank { Text("#\(rank)").monospacedDigit() }
                        Text(entry.userName ?? TrainingCopy.text("name.unknown"))
                        Spacer()
                        if let score = entry.score { Text(score.formatted()).monospacedDigit() }
                    }.accessibilityElement(children: .combine)
                }
            }
        }
    }
}
