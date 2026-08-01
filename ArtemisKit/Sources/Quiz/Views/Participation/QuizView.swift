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
    let startTime: Date?
    let endTime: Date?
    var questionsWithoutSolution: [DTO.QuizQuestionWithoutSolution]?
    var questionsWithSolution: [DTO.QuizQuestionWithSolution]?

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 0) {
            if let startTime, let endTime, endTime > .now {
                ProgressView(timerInterval: startTime...endTime, countsDown: false)
                    .labelsHidden()
                    .containerRelativeFrame(.horizontal)
            }
            TabView(selection: $viewModel.selectedQuestion) {
                if let questionsWithSolution {
                    QuizQuestionViews(questions: questionsWithSolution)
                } else if let questionsWithoutSolution {
                    let asQuestionsWithSolution = questionsWithoutSolution.compactMap { $0.asQuestionWithSolution() }
                    if asQuestionsWithSolution.count != questionsWithoutSolution.count {
                        Text("Some questions are not supported, this could cause strange issues! Please report this on GitHub.")
                    } else {
                        QuizQuestionViews(questions: asQuestionsWithSolution)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct QuizQuestionViews: View {
    @Environment(QuizParticipationViewModel.self) private var viewModel
    let questions: [DTO.QuizQuestionWithSolution]

    var body: some View {
        ForEach(questions.enumerated(), id: \.0) { index, question in
            ScrollView {
                VStack(alignment: .leading) {
                    let title = switch question {
                    case .dragAndDrop(let question): question.title
                    case .multipleChoice(let question): question.title
                    case .shortAnswer(let question): question.title
                    }
                    if let title {
                        Text(title)
                            .font(.title)
                            .padding(.horizontal)
                    }

                    switch question {
                    case .dragAndDrop(let dndQuestion):
                        DNDQuestionView(question: .init(quizQuestionWithSolutionDTO: .dragAndDrop(dndQuestion),
                                                        id: dndQuestion.id),
                                        questionWithAnswer: dndQuestion,
                                        previousAnswer: viewModel.getAnswer(for: dndQuestion.id))
                    case .multipleChoice(let mcQuestion):
                        MCQuestionView(question: .init(quizQuestionWithSolutionDTO: .multipleChoice(mcQuestion),
                                                       id: mcQuestion.id),
                                       questionWithAnswer: mcQuestion,
                                       previousAnswer: viewModel.getAnswer(for: mcQuestion.id))
                    case .shortAnswer(let saQuestion):
                        ShortAnswerQuestionView(question: .init(quizQuestionWithSolutionDTO: .shortAnswer(saQuestion),
                                                                id: saQuestion.id),
                                                questionWithSolution: saQuestion,
                                                previousAnswer: viewModel.getAnswer(for: saQuestion.id))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentMargins(.top, .m, for: .scrollContent)
            .contentMargins(.bottom, .l, for: .scrollContent)
            .contentMargins(.bottom, .l, for: .scrollIndicators)
            .tag(index)
            // Prevent manual swiping between questions
            .gesture(DragGesture())
        }
    }
}
