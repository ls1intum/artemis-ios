import Common
import SharedModels
import SwiftUI

enum QuizReviewCorrectness: Equatable {
    case unknown, correct, incorrect
    static func resolve(submitted: Bool, correct: Bool?) -> Self {
        guard submitted, let correct else { return .unknown }
        return correct ? .correct : .incorrect
    }
}

/// Displays the authorized selected attempt using the same MC, DnD and short-answer readers.
/// This model never starts a participation, opens a socket, or registers a submission timer.
public struct QuizResultReview: View {
    private let questions: [DTO.QuizQuestionWithSolution]
    private let answers: [DTO.SubmittedAnswerAfterEvaluation]
    @State private var viewModel: QuizViewModel

    public init(questions: [DTO.QuizQuestionWithSolution], answers: [DTO.SubmittedAnswerAfterEvaluation]) {
        self.questions = questions
        self.answers = answers
        let model = QuizViewModel()
        model.isReadOnly = true
        model.lastSubmissionResults = .done(response: answers)
        _viewModel = State(initialValue: model)
    }

    public var body: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            ForEach(questions.enumerated(), id: \.offset) { _, question in
                VStack(alignment: .leading, spacing: 12) {
                    let previous = answers.first(where: { $0.question?.id == question.id })?.reviewAnswer
                    switch question {
                    case .multipleChoice(let mc):
                        heading(title: mc.title, id: mc.id, points: mc.points)
                        MCQuestionView(question: .init(quizQuestionWithSolutionDTO: question, id: mc.id), questionWithAnswer: mc, previousAnswer: previous)
                    case .dragAndDrop(let dnd):
                        heading(title: dnd.title, id: dnd.id, points: dnd.points)
                        DNDQuestionView(question: .init(quizQuestionWithSolutionDTO: question, id: dnd.id), questionWithAnswer: dnd, previousAnswer: previous)
                    case .shortAnswer(let sa):
                        heading(title: sa.title, id: sa.id, points: sa.points)
                        ShortAnswerQuestionView(question: .init(quizQuestionWithSolutionDTO: question, id: sa.id), questionWithSolution: sa, previousAnswer: previous)
                    }
                }
                Divider()
            }
        }
        .environment(viewModel)
    }

    private func heading(title: String?, id: Int64?, points: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title ?? "").font(.title2.bold()).accessibilityAddTraits(.isHeader)
            if let score = viewModel.score(questionId: id), let points {
                Text("\(score.formatted()) / \(points.formatted())").font(.subheadline).monospacedDigit()
            }
        }.padding(.horizontal)
    }
}

extension DTO.SubmittedAnswerAfterEvaluation {
    var reviewAnswer: DTO.SubmittedAnswerFromLiveClient {
        switch self {
        case .multipleChoice(let mc):
            return .multipleChoice(.init(quizQuestion: .init(id: question?.id), selectedOptions: (mc.selectedOptions ?? []).compactMap(\.id).map { .init(id: $0) }, _type: .multipleChoice))
        case .dragAndDrop(let dnd):
            let mappings = (dnd.mappings ?? []).compactMap { mapping -> DTO.DragAndDropMappingFromLiveClient? in
                guard let drag = mapping.dragItem?.id, let drop = mapping.dropLocation?.id else { return nil }
                return .init(dragItem: .init(id: drag), dropLocation: .init(id: drop))
            }
            return .dragAndDrop(.init(quizQuestion: .init(id: question?.id), mappings: mappings, _type: .dragAndDrop))
        case .shortAnswer(let sa):
            return .shortAnswer(.init(quizQuestion: .init(id: question?.id), submittedTexts: (sa.submittedTexts ?? []).map {
                .init(text: $0.text, spot: .init(id: $0.spot?.id))
            }, _type: .shortAnswer))
        }
    }
}
