//
//  QuizView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.07.26.
//

import SharedModels
import SwiftUI

struct QuizView: View {
    @Environment(QuizParticipationViewModel.self) private var viewModel
    let endTime: Date?
    var questionsWithoutSolution: [DTO.QuizQuestionWithoutSolution]?
    var questionsWithSolution: [DTO.QuizQuestionWithSolution]?

    var body: some View {
        @Bindable var viewModel = viewModel
        TabView(selection: $viewModel.selectedQuestion) {
            if let questionsWithSolution {
                questionViews(questions: questionsWithSolution)
            } else if let questionsWithoutSolution {
                Text("Questions without solution not yet supported")
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .environment(QuizTrainingViewModel(courseId: 0))
    }

    private func questionViews(questions: [DTO.QuizQuestionWithSolution]) -> some View {
        ForEach(questions.enumerated(), id: \.0) { index, question in
            ScrollView {
                VStack(alignment: .leading) {
                    switch question {
                    case .dragAndDrop(let dndQuestion):
                        DNDQuestionView(question: .init(quizQuestionWithSolutionDTO: .dragAndDrop(dndQuestion),
                                                        id: dndQuestion.id),
                                        questionWithAnswer: dndQuestion)
                    case .multipleChoice(let mcQuestion):
                        MCQuestionView(question: .init(quizQuestionWithSolutionDTO: .multipleChoice(mcQuestion),
                                                       id: mcQuestion.id),
                                       questionWithAnswer: mcQuestion)
                    case .shortAnswer(let saQuestion):
                        ShortAnswerQuestionView(question: .init(quizQuestionWithSolutionDTO: .shortAnswer(saQuestion),
                                                                id: saQuestion.id),
                                                questionWithSolution: saQuestion)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tag(index)
            // Prevent manual swiping between questions
            .gesture(DragGesture())
        }
    }
}
