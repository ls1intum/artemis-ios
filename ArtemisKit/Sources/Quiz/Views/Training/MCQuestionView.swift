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
    @Environment(QuizTrainingViewModel.self) private var viewModel

    @State private var selectedAnswers = [Int64]()

    let question: DTO.QuizQuestionTraining
    let questionWithAnswer: DTO.MultipleChoiceQuizQuestionWithSolution

    var body: some View {
        if let text = questionWithAnswer.text {
            Text(LocalizedStringKey(text))
                .padding(.horizontal)
        }

        if let answerOptions = questionWithAnswer.answerOptions {
            ForEach(answerOptions, id: \.id) { option in
                let id = option.id ?? -1
                Button {
                    if selectedAnswers.contains(id) {
                        selectedAnswers.removeAll { $0 == id }
                    } else {
                        if questionWithAnswer.singleChoice == true {
                            selectedAnswers.removeAll()
                        }
                        selectedAnswers.append(id)
                    }
                } label: {
                    HStack(alignment: .center) {
                        Image(systemName: "circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .overlay(alignment: .center) {
                                if selectedAnswers.contains(id) {
                                    Image(systemName: "circle.fill")
                                        .resizable()
                                        .frame(width: 20, height: 20, alignment: .center)
                                }
                            }
                        Text(option.text ?? "No text")
                            .multilineTextAlignment(.leading)
                    }
                }

                if viewModel.hasSubmitted {
                    let loc = R.string.localizable
                    let optionIsCorrect = option.isCorrect ?? false

                    Text(optionIsCorrect ? loc.correct() : loc.incorrect())
                        .foregroundStyle(optionIsCorrect ? .green : .red)
                    + Text(option.explanation.map { ": " + $0 } ?? "")
                }
            }
            .padding(.horizontal)
            .disabled(viewModel.hasSubmitted)
        }

        SubmitAnswerButton(questionId: question.id, isRated: question.isRated, answer: answer)
    }

    var answer: QuizTrainingAnswer {
        let answers = selectedAnswers.map { DTO.EntityIdRef(id: $0) }
        return .MultipleChoiceSubmittedAnswerFromLiveClient(.init(
            .init(quizQuestion: .init(id: question.id),
                  selectedOptions: answers))
        )
    }
}
