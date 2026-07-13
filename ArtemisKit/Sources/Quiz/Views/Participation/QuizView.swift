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
    @State private var startTime = Date.now
    let endTime: Date?
    var questionsWithoutSolution: [DTO.QuizQuestionWithoutSolution]?
    var questionsWithSolution: [DTO.QuizQuestionWithSolution]?

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: .s) {
            if let endTime, endTime > .now {
                ProgressView(timerInterval: startTime...endTime, countsDown: false)
                    .labelsHidden()
                    .containerRelativeFrame(.horizontal)
            }
            TabView(selection: $viewModel.selectedQuestion) {
                if let questionsWithSolution {
                    questionViews(questions: questionsWithSolution)
                } else if let questionsWithoutSolution {
                    let asQuestionsWithSolution = questionsWithoutSolution.compactMap { $0.asQuestionWithSolution() }
                    if asQuestionsWithSolution.count != questionsWithoutSolution.count {
                        Text("Some questions are not supported, this could cause strange issues! Please report this on GitHub.")
                    }
                    questionViews(questions: asQuestionsWithSolution)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
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
