import Combine
import Common
import DesignLibrary
import Quiz
import SharedModels
import SwiftUI
import UserStore

struct ResultReviewPage: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var session = UserSessionFactory.shared
    let references: [ReviewReference]
    @State var reference: ReviewReference
    @State var generation = UUID()
    @State var transport: ReviewTransport?
    @State var document: ReviewDocument?
    @State var loading = true
    @State var error: String?
    @State var selectedFeedback: Int?
    @State var section = 0
    @State var previewURL: URL?
    @State var previewError: String?
    @State var fileLoading = false
    @State var source: String?
    @State var sourceName: String?
    @State var sourceError: String?
    @State var sourceLoading = false
    @State var logs: [ReviewBuildLog]?
    @State var logsError: String?
    @State var logsLoading = false
    @State var longLoading: Set<Int> = []
    @State var longErrors: Set<Int> = []
    @State var solution: ReviewExercise?
    @State var solutionError: String?
    @State var solutionLoading = false
    @State var showSolution = false

    init(references: [ReviewReference]) {
        self.references = references
        _reference = State(initialValue: references[0])
        _transport = State(initialValue: ReviewSession.current().map { ReviewTransport(captured: $0) })
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if let document {
                    summary(document)
                    Divider()
                    if geometry.size.width >= 800 && !typeSize.isAccessibilitySize && document.quiz == nil {
                        HStack(alignment: .top, spacing: 0) {
                            work(document).frame(maxWidth: .infinity)
                            Divider()
                            feedback(document).frame(width: min(440, geometry.size.width * 0.4))
                        }
                    } else if document.quiz != nil {
                        work(document)
                    } else {
                        Picker(ReviewCopy.text("review.section"), selection: $section) {
                            Text(ReviewCopy.text("review.work")).tag(0)
                            Text(ReviewCopy.text("review.feedback")).tag(1)
                        }.pickerStyle(.segmented).padding()
                        if section == 0 { work(document) } else { feedback(document) }
                    }
                } else if loading {
                    ProgressView(ReviewCopy.text("review.loading")).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView {
                        Label(ReviewCopy.text("review.unavailable"), systemImage: "doc.text.magnifyingglass")
                    } description: { Text(error ?? ReviewCopy.text("review.empty")) } actions: {
                        Button(ReviewCopy.text("review.retry")) { Task { await load() } }.buttonStyle(.bordered)
                    }
                }
            }
        }
        .navigationTitle(ReviewCopy.text("review.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: reference) { await load() }
        .onReceive(session.$isLoggedIn) { if !$0 { clear() } }
        .onReceive(session.$username) { if $0 != transport?.captured.username { clear() } }
        .onReceive(session.$institution) { if $0?.baseURL != transport?.captured.baseURL { clear() } }
        .onChange(of: scenePhase) { _, phase in if phase == .active && transport?.isCurrent != true { clear() } }
        .onDisappear { clear(); transport?.invalidate() }
    }

    private func summary(_ document: ReviewDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(document.exercise.title ?? "").font(.headline).textSelection(.enabled)
            HStack(alignment: .firstTextBaseline) {
                if let score = document.result.score {
                    let precision = min(10, max(0, document.exercise.course?.accuracyOfScores ?? 1))
                    VStack(alignment: .leading, spacing: 2) {
                        if let points = ReviewScore.points(score: score, maximum: document.exercise.maxPoints, precision: precision), let maximum = document.exercise.maxPoints {
                            Text("\(points.formatted()) / \(maximum.formatted()) \(ReviewCopy.text("review.points"))").font(.title3.bold())
                        }
                        Text("\(score.formatted(.number.precision(.fractionLength(0...precision)))) %").font(.subheadline)
                    }.monospacedDigit()
                } else { Text(ReviewCopy.text("review.scoreUnknown")).font(.headline) }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ReviewCopy.text(document.result.rated == false ? "review.practice" : "review.assessed"))
                    if document.preliminary { Text(ReviewCopy.text("review.preliminary")) }
                    if document.isLate == true { Text(ReviewCopy.text("review.late")) }
                    if document.submission.buildFailed == true { Text(ReviewCopy.text("review.buildFailed")) }
                }.font(.subheadline).foregroundStyle(.secondary)
            }
            if let passed = document.result.passedTestCaseCount, let total = document.result.testCaseCount, total > 0 {
                Text("\(passed) / \(total) \(ReviewCopy.text("review.tests"))").font(.subheadline).monospacedDigit()
            }
            if let issues = document.result.codeIssueCount, issues > 0 {
                Text("\(issues >= 255 ? "255+" : String(issues)) \(ReviewCopy.text("review.codeIssues"))").font(.subheadline)
            }
            if references.count > 1 {
                Picker(ReviewCopy.text("review.attempt"), selection: $reference) {
                    ForEach(references) { reference in Text(attemptTitle(reference)).tag(reference) }
                }.pickerStyle(.menu)
            } else { Text(attemptTitle(reference)).font(.subheadline).foregroundStyle(.secondary) }

            if let error { Text(error).font(.callout).foregroundStyle(.secondary) }
        }.padding().frame(maxWidth: .infinity, alignment: .leading)
    }

    private func attemptTitle(_ reference: ReviewReference) -> String {
        let date = reference.submissionDate ?? reference.completionDate
        if let date { return date.formatted(date: .abbreviated, time: .shortened) }
        let ordinal = references.firstIndex(of: reference).map { $0 + 1 } ?? 1
        return "\(ReviewCopy.text("review.attemptNumber")) \(ordinal)"
    }

    @ViewBuilder
    private func work(_ document: ReviewDocument) -> some View {
        if document.exercise.type == "text", let text = document.submission.text {
            VStack(alignment: .leading, spacing: 12) {
                AssessedTextView(text: text, blocks: document.submission.blocks ?? [], feedback: document.feedback,
                                 selected: selectedFeedback) { index in selectedFeedback = index; section = 1 }
                    .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
                if document.exercise.exampleSolutionPublicationDate != nil {
                    ScrollView { exampleSolution(document).padding() }.frame(maxHeight: showSolution ? 240 : 64)
                }
            }
        } else {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                assessedWork(document)
                exampleSolution(document)
            }.padding().frame(maxWidth: 800, alignment: .leading).frame(maxWidth: .infinity)
        }
        }
    }

    @ViewBuilder
    private func assessedWork(_ document: ReviewDocument) -> some View {
                switch document.exercise.type {
                case "text":
                    if let text = document.submission.text {
                        AssessedTextView(text: text, blocks: document.submission.blocks ?? [], feedback: document.feedback,
                                         selected: selectedFeedback) { index in selectedFeedback = index; section = 1 }
                            .frame(minHeight: 280)
                    } else { unavailable("review.sourceUnavailable") }
                case "file-upload":
                    fileWork(document)
                case "programming":
                    programmingWork(document)
                case "modeling":
                    if let model = document.submission.model {
                        ModelReviewCanvas(model: model, diagramType: document.exercise.diagramType,
                                          feedback: document.feedback,
                                          selectedReference: selectedReference(document)) { reference in
                            selectedFeedback = document.feedback.firstIndex(where: { $0.reference == reference }); section = 1
                        }.frame(minHeight: 460)
                    } else { unavailable("review.sourceUnavailable") }
                    if let explanation = document.submission.explanationText, !explanation.isEmpty { Text(explanation).textSelection(.enabled) }
                case "quiz":
                    quizWork(document)
                default: unavailable("review.sourceUnavailable")
                }
    }

    @ViewBuilder
    private func exampleSolution(_ document: ReviewDocument) -> some View {
                if document.exercise.type != "quiz", document.exercise.exampleSolutionPublicationDate != nil {
                    Divider()
                    DisclosureGroup(ReviewCopy.text("review.solution"), isExpanded: $showSolution) {
                        if let solution {
                            if let model = solution.exampleSolutionModel {
                                ModelReviewCanvas(model: model, diagramType: solution.diagramType, feedback: [], selectedReference: nil) { _ in }.frame(minHeight: 400)
                            }
                            if let text = solution.exampleSolution { Text(text).textSelection(.enabled) }
                            if let explanation = solution.exampleSolutionExplanation { Text(explanation).textSelection(.enabled) }
                            if solution.type == "programming", let url = try? transport?.captured.url(for: "/courses/\(reference.courseID)/exercises/\(reference.exerciseID)") {
                                Link(ReviewCopy.text("review.openSolutionWeb"), destination: url)
                                Text(ReviewCopy.text("review.browserSignIn")).font(.caption).foregroundStyle(.secondary)
                            } else if solution.exampleSolution == nil && solution.exampleSolutionModel == nil {
                                unavailable("review.solutionUnavailable")
                            }
                        } else {
                            if let solutionError { Text(solutionError).foregroundStyle(.secondary) }
                            Button(ReviewCopy.text("review.loadSolution")) { Task { await loadSolution() } }.disabled(solutionLoading)
                            if solutionLoading { ProgressView() }
                        }
                    }
                }
    }

    private func feedback(_ document: ReviewDocument) -> some View {
        ScrollViewReader { proxy in
            List {
                if document.feedback.isEmpty {
                    Text(ReviewCopy.text("review.empty")).foregroundStyle(.secondary)
                }
                ForEach(StudentFeedback.Group.allCases, id: \.self) { group in
                    let indices = document.feedback.indices.filter { document.feedback[$0].group == group }
                    if !indices.isEmpty {
                        Section(ReviewCopy.group(group)) {
                            ForEach(indices, id: \.self) { index in
                                FeedbackReviewRow(feedback: document.feedback[index], selected: selectedFeedback == index,
                                                  loading: longLoading.contains(index), failed: longErrors.contains(index),
                                                  referenceLabel: feedbackLocation(index, document: document),
                                                  unlocated: document.feedback[index].reference != nil && feedbackLocation(index, document: document) == nil,
                                                  onSelect: { focusFeedback(index, document: document) },
                                                  onLong: { Task { await loadLong(index) } })
                                    .id(index)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .onAppear { if let selectedFeedback { proxy.scrollTo(selectedFeedback, anchor: .center) } }
            .onChange(of: selectedFeedback) { _, index in if let index { proxy.scrollTo(index, anchor: .center) } }
        }
    }

    private func feedbackLocation(_ index: Int, document: ReviewDocument) -> String? {
        let feedback = document.feedback[index]
        switch document.exercise.type {
        case "text":
            guard ReviewTextAnchor.resolve(reference: feedback.reference, blocks: document.submission.blocks ?? [], text: document.submission.text ?? "") != nil else { return nil }
            return ReviewCopy.text("review.showPassage")
        case "modeling":
            return feedback.reference == nil ? nil : ReviewCopy.text("review.showElement")
        case "programming":
            guard let reference = feedback.sourceReference, let location = ReviewCodeLocation(reference: reference) else { return nil }
            return "\(location.file):\(location.firstLine + 1)–\(location.lastLine + 1)"
        default: return nil
        }
    }

    private func focusFeedback(_ index: Int, document: ReviewDocument) {
        selectedFeedback = index
        if document.exercise.type == "text" {
            if ReviewTextAnchor.resolve(reference: document.feedback[index].reference, blocks: document.submission.blocks ?? [], text: document.submission.text ?? "") != nil { section = 0 }
        } else if document.exercise.type == "modeling" { section = 0 } else if document.exercise.type == "programming", let reference = document.feedback[index].sourceReference,
                let location = ReviewCodeLocation(reference: reference) {
            section = 0
            Task { await loadSource(location.file) }
        }
    }

    private func selectedReference(_ document: ReviewDocument) -> String? {
        guard let selectedFeedback, document.feedback.indices.contains(selectedFeedback) else { return nil }
        return document.feedback[selectedFeedback].reference
    }

    func unavailable(_ key: String) -> some View {
        Text(ReviewCopy.text(key)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
    }

    @MainActor
    private func load() async {
        let selected = reference
        let generation = UUID()
        self.generation = generation
        document = nil
        cleanupFile()
        selectedFeedback = nil; source = nil; logs = nil; solution = nil
        previewError = nil; sourceError = nil; logsError = nil; solutionError = nil
        longErrors = []; longLoading = []
        fileLoading = false; sourceLoading = false; logsLoading = false; solutionLoading = false
        showSolution = false
        error = nil; loading = true
        defer { if reference == selected && self.generation == generation { loading = false } }
        guard let transport, transport.isCurrent else { clear(); return }
        do {
            let loaded = try await ReviewLoader(reader: transport).load(selected)
            guard reference == selected, self.generation == generation, transport.isCurrent else { return }
            document = loaded
        } catch {
            guard reference == selected, self.generation == generation else { return }
            self.error = ReviewCopy.error(error)
        }
    }

    @MainActor
    func clear() {
        generation = UUID()
        document = nil; source = nil; logs = nil; solution = nil; selectedFeedback = nil
        cleanupFile()
        loading = false
        error = ReviewCopy.text("review.sessionChanged")
    }
    func cleanupFile() {
        if let previewURL { try? FileManager.default.removeItem(at: previewURL.deletingLastPathComponent()) }
        previewURL = nil
    }
}
