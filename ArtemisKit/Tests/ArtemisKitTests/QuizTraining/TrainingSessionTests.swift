import SharedModels
import XCTest
@testable import Quiz

@MainActor
final class TrainingSessionTests: XCTestCase {
    func testRatedSnapshotIsImmutableAcrossPagesAndAnswers() async throws {
        let service = TrainingStub(pages: [try page(1...10, next: true), try page(11...12, next: false)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions()
        for _ in 0..<10 {
            await model.submitAnswer(questionId: model.currentQuestion!.id!, isRated: true, answer: answer)
            await model.advance()
        }
        XCTAssertEqual(model.phase, .summary)
        XCTAssertEqual(model.confirmedCount, 10)
        await model.continueTraining()
        XCTAssertEqual(model.currentQuestion?.id, 11)
        XCTAssertEqual(service.requests.last, TrainingPageRequest(page: 1, isNewSession: false, questionIDs: [91, 93]))
        XCTAssertEqual(service.submits, 10)
    }

    func testLegacyUnratedContinuationUsesFreshFlagButRejectsChangedRating() async throws {
        let service = TrainingStub(pages: [try page(1...1, rated: false, snapshot: nil, next: true), try page(2...2, next: false)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions()
        XCTAssertEqual(model.phase, .unratedConfirmation)
        model.acceptUnratedPractice()
        await model.submitAnswer(questionId: 1, isRated: false, answer: answer)
        await model.advance()
        XCTAssertEqual(model.phase, .revisionRequired)
        XCTAssertNil(model.currentQuestion)
        XCTAssertEqual(service.requests.last, TrainingPageRequest(page: 1, isNewSession: true, questionIDs: []))
    }

    func testPageFailureRetainsIndexAndExplicitRetry() async throws {
        let service = TrainingStub(pages: [try page(1...1, next: true), try page(2...2, next: false)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions()
        await model.submitAnswer(questionId: 1, isRated: true, answer: answer)
        service.failPage = true
        await model.advance()
        XCTAssertEqual(model.phase, .pageFailure)
        service.failPage = false
        await model.retryPage()
        XCTAssertEqual(service.requests.suffix(2).map(\.page), [1, 1])
        XCTAssertEqual(model.currentQuestion?.id, 2)
    }

    func testAmbiguousSubmissionRequiresFrozenExplicitRetry() async throws {
        let service = TrainingStub(pages: [try page(1...1, next: false)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions()
        service.failSubmit = true
        await model.submitAnswer(questionId: 1, isRated: true, answer: answer)
        XCTAssertEqual(model.phase, .uncertain)
        await model.submitAnswer(questionId: 1, isRated: true, answer: .multipleChoice(.init(selectedOptions: [.init(id: 999)], _type: .multipleChoice)))
        XCTAssertEqual(service.submits, 1)
        await model.loadQuestions()
        XCTAssertEqual(service.submits, 1)
        service.failSubmit = false
        await model.retrySubmission()
        XCTAssertEqual(service.submits, 2)
        XCTAssertEqual(service.answers.first, service.answers.last)
        XCTAssertEqual(model.confirmedCount, 1)
    }

    func testStaleAccountClearsQuestionAndFeedback() async throws {
        let service = TrainingStub(pages: [try page(1...1, next: false)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions()
        service.isCurrent = false
        model.validateSession()
        XCTAssertNil(model.currentQuestion)
        XCTAssertEqual(model.phase, .accessLost)
        await model.submitAnswer(questionId: 1, isRated: true, answer: answer)
        XCTAssertEqual(service.submits, 0)
    }

    func testEmptyPageClaimingMoreIsRecoverable() async {
        let service = TrainingStub(pages: [.init(questions: [], hasNext: true)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions()
        XCTAssertEqual(model.phase, .pageFailure)
        XCTAssertEqual(service.requests.count, 1)
    }

    func testDuplicatesWithinPageArePresentedOnlyOnce() async throws {
        let first = try page(1...1, next: false)
        let service = TrainingStub(pages: [.init(questions: first.questions + first.questions, hasNext: false)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions()
        XCTAssertEqual(model.questions.count, 1)
    }

    func testConcurrentSubmitHasOneWriteAndStaleCompletionCannotApply() async throws {
        let service = TrainingStub(pages: [try page(1...1, next: false)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions()
        service.pauseSubmit = true
        let first = Task { await model.submitAnswer(questionId: 1, isRated: true, answer: answer) }
        while service.pendingSubmit == nil { await Task.yield() }
        await model.submitAnswer(questionId: 1, isRated: true, answer: answer)
        XCTAssertEqual(service.submits, 1)
        service.isCurrent = false
        service.pendingSubmit?.resume(); service.pendingSubmit = nil
        await first.value
        XCTAssertEqual(model.phase, .accessLost)
        XCTAssertEqual(model.confirmedCount, 0)
        XCTAssertNil(model.currentQuestion)
        XCTAssertNil(model.lastSubmissionResult.value)
    }

    func testWrongEvaluationSubtypeDoesNotConfirmAnAnswer() async throws {
        let json = #"{"id":1,"isRated":true,"isNewSession":false,"questionIds":[],"quizQuestionWithSolutionDTO":{"id":1,"type":"short-answer","text":"[-spot 1]","spots":[{"id":913,"spotNr":1}]}}"#
        let question = try JSONDecoder().decode(DTO.QuizQuestionTraining.self, from: Data(json.utf8))
        let service = TrainingStub(pages: [.init(questions: [question], hasNext: false)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions()
        let answer = DTO.SubmittedAnswerFromLiveClient.shortAnswer(.init(quizQuestion: .init(id: 1), submittedTexts: [.init(text: "Answer", spot: .init(id: 913))], _type: .shortAnswer))
        await model.submitAnswer(questionId: 1, isRated: true, answer: answer)
        XCTAssertEqual(model.phase, .uncertain)
        XCTAssertEqual(model.confirmedCount, 0)
        XCTAssertNil(model.lastSubmissionResult.value)
    }

    func testLiveRatedPagesWithOmittedEmptySnapshotContinueWithFalseAndEmptyIDs() async throws {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: Self.self)
        #endif
        var pages: [TrainingPage] = []
        for page in 0...1 {
            let name = "training-live-rated-page\(page)"
            let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") ?? bundle.url(forResource: name, withExtension: "json"))
            let questions = try JSONDecoder().decode([DTO.QuizQuestionTraining].self, from: Data(contentsOf: url))
            XCTAssertTrue(questions.allSatisfy { $0.isRated == true && $0.questionIds == nil })
            pages.append(.init(questions: questions, hasNext: true))
        }
        let service = TrainingStub(pages: pages)
        let model = QuizTrainingViewModel(courseId: 14, transport: service)
        await model.loadQuestions()
        XCTAssertEqual(model.phase, .answering)
        guard model.phase == .answering else { return }
        for _ in 0..<10 { await model.skip() }
        XCTAssertEqual(service.requests.last, .init(page: 1, isNewSession: false, questionIDs: []))
        XCTAssertEqual(model.phase, .answering)
    }

    private var answer: DTO.SubmittedAnswerFromLiveClient {
        .multipleChoice(.init(quizQuestion: .init(id: 1), selectedOptions: [.init(id: 21)], _type: .multipleChoice))
    }
    private func page(_ ids: ClosedRange<Int>, rated: Bool = true, snapshot: [Int64]? = [91, 93], next: Bool) throws -> TrainingPage {
        let questions = try ids.map { id in
            let snapshotJSON = snapshot.map { "[" + $0.map(String.init).joined(separator: ",") + "]" } ?? "null"
            let json = """
            {"id":\(id),"isRated":\(rated),"isNewSession":false,"questionIds":\(snapshotJSON),
            "quizQuestionWithSolutionDTO":{"type":"multiple-choice","id":\(id),"title":"Question","points":0,"answerOptions":[]}}
            """
            return try JSONDecoder().decode(DTO.QuizQuestionTraining.self, from: Data(json.utf8))
        }
        return .init(questions: questions, hasNext: next)
    }
}

final class TrainingStub: TrainingServing {
    var isCurrent = true
    var pages: [TrainingPage]
    var requests: [TrainingPageRequest] = []
    var submits = 0
    var answers: [Data] = []
    var failPage = false
    var failSubmit = false
    var pauseSubmit = false
    var pendingSubmit: CheckedContinuation<Void, Never>?
    init(pages: [TrainingPage]) { self.pages = pages }
    func page(_ request: TrainingPageRequest) async throws -> TrainingPage {
        requests.append(request)
        if failPage { throw URLError(.notConnectedToInternet) }
        return pages.removeFirst()
    }
    func submit(questionID: Int64, rated: Bool, answer: Data) async throws -> DTO.SubmittedAnswerAfterEvaluation {
        submits += 1; answers.append(answer)
        if pauseSubmit { await withCheckedContinuation { pendingSubmit = $0 } }
        if failSubmit { throw URLError(.networkConnectionLost) }
        return try JSONDecoder().decode(DTO.SubmittedAnswerAfterEvaluation.self, from: Data("{\"type\":\"multiple-choice\",\"quizQuestion\":{\"id\":\(questionID),\"type\":\"multiple-choice\"},\"scoreInPoints\":0}".utf8))
    }
}
