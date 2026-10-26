//
//  MCQuestionView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.06.26.
//

import Common
import SharedModels
import SwiftUI

struct MCQuestionView: View {
    @Environment(QuizViewModel.self) private var viewModel

    @State private var selectedAnswers = [Int64]()

    let question: DTO.QuizQuestionTraining
    let questionWithAnswer: DTO.MultipleChoiceQuizQuestionWithSolution

    init(question: DTO.QuizQuestionTraining,
         questionWithAnswer: DTO.MultipleChoiceQuizQuestionWithSolution,
         previousAnswer: DTO.SubmittedAnswerFromLiveClient? = nil) {
        self.question = question
        self.questionWithAnswer = questionWithAnswer
        if let previousAnswer, case let .multipleChoice(answer) = previousAnswer {
            _selectedAnswers = State(initialValue: (answer.selectedOptions ?? []).compactMap(\.id))
        }
    }

    var body: some View {
        if let text = questionWithAnswer.text {
            Text(LocalizedStringKey(text))
                .padding(.horizontal)
        }

        if let answerOptions = questionWithAnswer.answerOptions {
            ForEach(answerOptions, id: \.id) { option in
                let id = option.id ?? -1
                if viewModel.hasSubmitted {
                    choiceLabel(option).foregroundStyle(.primary)
                } else {
                    Button { toggleAnswer(id) } label: { choiceLabel(option) }
                }

                if QuizReviewCorrectness.resolve(submitted: viewModel.hasSubmitted, correct: option.isCorrect) != .unknown {
                    let optionIsCorrect = QuizReviewCorrectness.resolve(submitted: viewModel.hasSubmitted, correct: option.isCorrect) == .correct
                    let loc = R.string.localizable

                    let correctLabel = Text(optionIsCorrect ? loc.correct() : loc.incorrect())
                        .foregroundStyle(optionIsCorrect ? .green : .red)

                    Text("\(loc.solution()): \(correctLabel)")
                    if let explanation = option.explanation {
                        Text("\(loc.explanation()): \(explanation)")
                    }
                }
            }
            .padding(.horizontal)
        }

        SubmitAnswerButton(questionId: question.id, isRated: question.isRated, answer: answer)
    }

    private func choiceLabel(_ option: DTO.AnswerOptionWithSolution) -> some View {
        let id = option.id ?? -1
                    return HStack(alignment: .center) {
                        Image(systemName: questionWithAnswer.singleChoice == true ? "circle" : "square")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .overlay(alignment: .center) {
                                if selectedAnswers.contains(id) {
                                    Image(systemName: questionWithAnswer.singleChoice == true ? "circle.fill" : "square.fill")
                                        .resizable()
                                        .frame(width: 20, height: 20, alignment: .center)
                                }
                            }
                            .accessibilityHidden(true)
                            .overlay(alignment: .bottomTrailing) {
                                if viewModel.hasSubmitted, let correct = option.isCorrect, selectedAnswers.contains(id) != correct {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .offset(x: 8, y: 4)
                                }
                            }

                        Text(option.text ?? "No text")
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityAddTraits(selectedAnswers.contains(id) ? .isSelected : [])

                        if let hint = option.hint {
                            HintButton(hint: hint)
                                .font(.title2)
                        }
                    }
    }

    private func toggleAnswer(_ id: Int64) {
        if selectedAnswers.contains(id) {
            selectedAnswers.removeAll { $0 == id }
        } else {
            if questionWithAnswer.singleChoice == true { selectedAnswers.removeAll() }
            selectedAnswers.append(id)
        }
    }

    var answer: DTO.SubmittedAnswerFromLiveClient {
        let answers = selectedAnswers.map { DTO.EntityIdRef(id: $0) }
        return .multipleChoice(.init(quizQuestion: .init(id: question.id), selectedOptions: answers, _type: .multipleChoice))
    }
}
