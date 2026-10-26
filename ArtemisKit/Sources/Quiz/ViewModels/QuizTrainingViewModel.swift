import Common
import Foundation
import ReviewContent
import SharedModels

/// One course-owned, memory-only session. View appearances never replay answer writes.
@Observable
@MainActor
class QuizTrainingViewModel: QuizViewModel {
    let courseId: Int
    let scorePrecision: Int
    let transport: TrainingServing
    private(set) var phase: TrainingPhase = .idle
    private(set) var confirmedCount = 0
    private(set) var ratedCount = 0
    private(set) var questions: [DTO.QuizQuestionTraining] = []
    private(set) var draft: DTO.SubmittedAnswerFromLiveClient?
    private var nextRequest = TrainingPageRequest()
    private var frozenSnapshot: [Int64]?
    private var frozenNewSession: Bool?
    private var legacyUnrated = false
    private var seen: Set<Int64> = []
    private var hasNext = false
    private var summaryAt = 10
    private var lastPresentedRated: Bool?
    private var generation = UUID()
    private var frozenSubmission: (questionID: Int64, rated: Bool, body: Data)?

    func formattedPoints(_ points: Double) -> String { points.formatted(.number.precision(.fractionLength(0...scorePrecision))) }
    var currentQuestion: DTO.QuizQuestionTraining? { questions.first }
    var inputsLocked: Bool { phase != .answering }
    var hasActiveSession: Bool { phase != .idle && phase != .accessLost }
    var currentScore: (reached: Double, total: Double)? {
        guard let question = currentQuestion, let result = lastSubmissionResult.value, let reached = TrainingProjection.points(result) else { return nil }
        let total: Double?
        switch question.quizQuestionWithSolutionDTO {
        case .multipleChoice(let value): total = value.points
        case .dragAndDrop(let value): total = value.points
        case .shortAnswer(let value): total = value.points
        }
        guard let total, total.isFinite, reached.isFinite else { return nil }
        return (reached, total)
    }

    init(courseId: Int, transport: TrainingServing? = nil, scorePrecision: Int = 1) {
        self.courseId = courseId
        self.scorePrecision = min(10, max(0, scorePrecision))
        self.transport = transport ?? TrainingIdentity.current(courseID: courseId).map { TrainingTransport(captured: $0) } ?? UnavailableTrainingTransport()
    }
    func validateSession() {
        guard !transport.isCurrent else { return }
        generation = UUID(); questions = []; draft = nil; frozenSubmission = nil
        lastSubmissionResult = .loading; lastSubmissionResults = .loading; phase = .accessLost
    }
    func updateDraft(_ answer: DTO.SubmittedAnswerFromLiveClient) {
        guard phase == .answering, transport.isCurrent else { return }
        draft = answer
    }
    func loadQuestions() async {
        validateSession()
        guard phase == .idle else { return }
        await fetchPage()
    }
    func retryPage() async {
        guard phase == .pageFailure else { return }
        await fetchPage()
    }
    private func fetchPage() async {
        validateSession()
        guard phase != .accessLost, phase != .loading else { return }
        let capturedGeneration = generation
        phase = .loading
        do {
            let response = try await transport.page(nextRequest)
            validateSession()
            guard generation == capturedGeneration, transport.isCurrent else { return }
            if legacyUnrated, response.questions.contains(where: { $0.isRated != false }) {
                questions = []; phase = .revisionRequired; return
            }
            var pageSeen = seen
            var unique: [DTO.QuizQuestionTraining] = []
            for question in response.questions {
                guard let id = question.id, id == TrainingProjection.id(question.quizQuestionWithSolutionDTO), question.isRated != nil else { throw TrainingError.contract }
                if pageSeen.insert(id).inserted { unique.append(question) }
            }
            guard !response.hasNext || !unique.isEmpty else { throw TrainingError.contract }
            try captureSnapshot(response)
            seen = pageSeen
            questions = unique; hasNext = response.hasNext
            nextRequest.page += 1
            if legacyUnrated {
                nextRequest.isNewSession = true; nextRequest.questionIDs = []
            } else {
                nextRequest.isNewSession = frozenNewSession ?? false; nextRequest.questionIDs = frozenSnapshot ?? []
            }
            prepareQuestion()
        } catch {
            validateSession()
            if generation == capturedGeneration, phase != .accessLost {
                if case TrainingError.denied = error { loseAccess() } else { phase = .pageFailure }
            }
        }
    }
    private func captureSnapshot(_ page: TrainingPage) throws {
        guard let first = page.questions.first else { return }
        if frozenSnapshot == nil, !legacyUnrated {
            if let snapshot = first.questionIds, let newSession = first.isNewSession {
                guard page.questions.allSatisfy({ $0.questionIds == snapshot && $0.isNewSession == newSession }) else { throw TrainingError.contract }
                frozenSnapshot = snapshot; frozenNewSession = newSession
            } else if first.isRated == true, let newSession = first.isNewSession {
                // NON_EMPTY omits the rated branch's valid empty exclusion Set on deployed servers.
                guard page.questions.allSatisfy({ $0.isRated == true && ($0.questionIds ?? []).isEmpty && $0.isNewSession == newSession }) else { throw TrainingError.contract }
                frozenSnapshot = []; frozenNewSession = newSession
            } else {
                guard page.questions.allSatisfy({ $0.questionIds == nil && $0.isRated == false }) else { throw TrainingError.contract }
                legacyUnrated = true
            }
        }
    }
    private func prepareQuestion() {
        guard let question = currentQuestion else { phase = confirmedCount == 0 ? .empty : .summary; return }
        if question.isRated == false, lastPresentedRated != false {
            phase = .unratedConfirmation
        } else {
            lastPresentedRated = question.isRated; phase = .answering
        }
    }
    func acceptUnratedPractice() {
        guard phase == .unratedConfirmation else { return }
        lastPresentedRated = false; phase = .answering
    }
    func submitAnswer(questionId: Int64, isRated: Bool, answer: DTO.SubmittedAnswerFromLiveClient) async {
        validateSession()
        guard phase == .answering, let question = currentQuestion, question.id == questionId, question.isRated == isRated else { return }
        do {
            var payload = answer
            switch payload {
            case .multipleChoice(var value): value.quizQuestion = .init(id: questionId); payload = .multipleChoice(value)
            case .dragAndDrop(var value): value.quizQuestion = .init(id: questionId); payload = .dragAndDrop(value)
            case .shortAnswer(var value): value.quizQuestion = .init(id: questionId); payload = .shortAnswer(value)
            }
            draft = payload
            frozenSubmission = (questionId, isRated, try JSONEncoder().encode(payload))
            await sendFrozenSubmission()
        } catch { phase = .uncertain }
    }
    func retrySubmission() async {
        guard phase == .uncertain else { return }
        await sendFrozenSubmission()
    }
    private func sendFrozenSubmission() async {
        validateSession()
        guard phase != .accessLost, let frozen = frozenSubmission else { return }
        let capturedGeneration = generation
        phase = .submitting
        do {
            let result = try await transport.submit(questionID: frozen.questionID, rated: frozen.rated, answer: frozen.body)
            validateSession()
            guard generation == capturedGeneration, currentQuestion?.id == frozen.questionID, transport.isCurrent else { return }
            if let id = result.question?.id, id != frozen.questionID { throw TrainingError.contract }
            guard let question = currentQuestion, TrainingProjection.matches(question.quizQuestionWithSolutionDTO, evaluation: result) else { throw TrainingError.contract }
            lastSubmissionResult = .done(response: result)
            confirmedCount += 1; if frozen.rated { ratedCount += 1 }
            phase = .evaluated
        } catch {
            validateSession()
            if generation == capturedGeneration, phase != .accessLost {
                if case TrainingError.denied = error { loseAccess() } else { phase = .uncertain }
            }
        }
    }
    func advance() async {
        guard phase == .evaluated else { return }
        removeCurrent()
        if confirmedCount >= summaryAt { phase = .summary; return }
        await nextQuestion()
    }
    func skip() async {
        guard phase == .answering else { return }
        removeCurrent(); await nextQuestion()
    }
    private func removeCurrent() {
        if !questions.isEmpty { questions.removeFirst() }
        draft = nil; frozenSubmission = nil; lastSubmissionResult = .loading
    }
    private func nextQuestion() async {
        if !questions.isEmpty { prepareQuestion() } else if hasNext { await fetchPage() } else { phase = confirmedCount == 0 ? .empty : .summary }
    }
    func continueTraining() async {
        guard phase == .summary else { return }
        summaryAt = confirmedCount + 10
        if questions.isEmpty, !hasNext { resetCursor() }
        await nextQuestion()
    }
    func startFreshRevision() async {
        guard phase == .revisionRequired || phase == .empty else { return }
        resetCursor(); await fetchPage()
    }
    private func resetCursor() {
        nextRequest = TrainingPageRequest(); frozenSnapshot = nil; frozenNewSession = nil; legacyUnrated = false
        seen = []; hasNext = true; lastPresentedRated = nil
    }
    func finish() {
        guard phase != .submitting else { return }
        questions = []; draft = nil; frozenSubmission = nil; lastSubmissionResult = .loading
        confirmedCount = 0; ratedCount = 0; summaryAt = 10; resetCursor(); phase = .idle; generation = UUID()
    }
    func loseAccess() {
        questions = []; draft = nil; frozenSubmission = nil; lastSubmissionResult = .loading
        generation = UUID(); phase = .accessLost
    }
}

private struct UnavailableTrainingTransport: TrainingServing {
    var isCurrent: Bool { false }
    func page(_ request: TrainingPageRequest) async throws -> TrainingPage { throw TrainingError.unavailable }
    func submit(questionID: Int64, rated: Bool, answer: Data) async throws -> DTO.SubmittedAnswerAfterEvaluation { throw TrainingError.unavailable }
}
