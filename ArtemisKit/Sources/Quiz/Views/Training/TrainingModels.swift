import Foundation
import SharedModels

struct TrainingPageRequest: Equatable {
    var page = 0
    var isNewSession = true
    var questionIDs: [Int64] = []
}

struct TrainingPage {
    let questions: [DTO.QuizQuestionTraining]
    let hasNext: Bool
}

enum TrainingPhase: Equatable {
    case idle, loading, answering, submitting, evaluated, uncertain, pageFailure
    case unratedConfirmation, revisionRequired, summary, accessLost, empty
}

enum TrainingError: Error { case unavailable, identity, denied, contract, http(Int) }

protocol TrainingServing {
    var isCurrent: Bool { get }
    func page(_ request: TrainingPageRequest) async throws -> TrainingPage
    func submit(questionID: Int64, rated: Bool, answer: Data) async throws -> DTO.SubmittedAnswerAfterEvaluation
}

/// The answering projection physically removes grading data before handing it to native bodies.
enum TrainingProjection {
    static func answering(_ original: DTO.QuizQuestionTraining) -> DTO.QuizQuestionTraining {
        var question = original
        switch original.quizQuestionWithSolutionDTO {
        case .multipleChoice(var value):
            value.explanation = nil
            value.answerOptions = value.answerOptions?.map { original in
                var option = original; option.isCorrect = nil; option.explanation = nil; return option
            }
            question.quizQuestionWithSolutionDTO = .multipleChoice(value)
        case .dragAndDrop(var value):
            value.explanation = nil; value.correctMappings = nil
            question.quizQuestionWithSolutionDTO = .dragAndDrop(value)
        case .shortAnswer(var value):
            value.explanation = nil; value.correctMappings = nil; value.solutions = nil
            question.quizQuestionWithSolutionDTO = .shortAnswer(value)
        }
        return question
    }
    static func shortAnswerInputs(question: DTO.ShortAnswerQuizQuestionWithSolution) -> [DTO.ShortAnswerSubmittedTextFromLiveClient] {
        ShortAnswerReviewPresentation(question: question, answer: nil).segments.compactMap { segment in
            guard case .answer(let answer) = segment, let id = answer.spotID else { return nil }
            return .init(text: "", spot: .init(id: id))
        }
    }
    static func canAnswer(_ question: DTO.QuizQuestionTraining) -> Bool {
        switch question.quizQuestionWithSolutionDTO {
        case .multipleChoice(let value):
            guard let options = value.answerOptions, !options.isEmpty else { return false }
            return options.allSatisfy { $0.id != nil }
        case .dragAndDrop(let value):
            guard let locations = value.dropLocations, !locations.isEmpty, let items = value.dragItems, !items.isEmpty else { return false }
            return items.allSatisfy { $0.id != nil } && locations.allSatisfy { location in
                guard location.id != nil, let x = location.posX, let y = location.posY, let width = location.width, let height = location.height else { return false }
                return x.isFinite && y.isFinite && width.isFinite && height.isFinite && x >= 0 && y >= 0 && width > 0 && height > 0 && x + width <= 200 && y + height <= 200
            }
        case .shortAnswer(let value):
            let presentation = ShortAnswerReviewPresentation(question: value, answer: nil)
            let answers = presentation.segments.compactMap { segment -> ShortAnswerReviewPresentation.Answer? in
                guard case .answer(let answer) = segment else { return nil }; return answer
            }
            return !answers.isEmpty && answers.allSatisfy { $0.spotID != nil }
        }
    }
    static func matches(_ question: DTO.QuizQuestionWithSolution, evaluation: DTO.SubmittedAnswerAfterEvaluation) -> Bool {
        switch (question, evaluation) {
        case (.multipleChoice, .multipleChoice), (.dragAndDrop, .dragAndDrop), (.shortAnswer, .shortAnswer): true
        default: false
        }
    }
    static func points(_ result: DTO.SubmittedAnswerAfterEvaluation) -> Double? {
        switch result {
        case .multipleChoice(let value): value.scoreInPoints
        case .dragAndDrop(let value): value.scoreInPoints
        case .shortAnswer(let value): value.scoreInPoints
        }
    }
    static func id(_ question: DTO.QuizQuestionWithSolution) -> Int64? {
        switch question {
        case .multipleChoice(let value): value.id
        case .dragAndDrop(let value): value.id
        case .shortAnswer(let value): value.id
        }
    }
}
