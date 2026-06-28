//
//  QuizTraingQuestionsView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.06.26.
//

import DesignLibrary
import SharedModels
import SwiftUI

struct QuizTraingQuestionsView: View {

    @State private var viewModel: QuizTrainingViewModel

    init(courseId: Int) {
        _viewModel = State(initialValue: QuizTrainingViewModel(courseId: courseId))
    }

    var body: some View {
        DataStateView(data: $viewModel.questions) {
            await viewModel.loadQuestions()
        } content: { questions in
            if let question = questions.first {
                QuizQuestionView(question: question)
                    .toolbar {
                        if let score = viewModel.currentScore {
                            ToolbarItem(placement: .topBarTrailing) {
                                let percent = score.reached / score.total
                                Button {
                                    // This needs to be a button, otherwise .tint has no effect
                                } label: {
                                    Text("\(score.reached.formatted(.number)) / \(score.total.formatted(.number))")
                                        .padding(.horizontal, .s)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(percent > 0.8 ? .green : percent > 0.4 ? .yellow : .red)
                            }
                        }
                    }
            } else {
                VStack(alignment: .center) {
                    Text("🎉")
                        .font(.largeTitle)
                    Text("No more questions for now")
                        .font(.title2)
                }
            }
        }
        .interactiveDismissDisabled()
        .environment(viewModel)
        .task(id: "loadQuestions") {
            viewModel.questions = .loading
            await viewModel.loadQuestions()
        }
    }
}

struct QuizQuestionView: View {
    let question: DTO.QuizQuestionTraining

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .m) {
                if let title {
                    Text(title)
                        .font(.title)
                        .padding(.horizontal)
                }

                switch question.quizQuestionWithSolutionDTO {
                case .multipleChoice(let mcQuestion):
                    MCQuestionView(question: question, questionWithAnswer: mcQuestion)
                case .dragAndDrop(let dndQuestion):
                    DNDQuestionView(question: question, questionWithAnswer: dndQuestion)
                case .shortAnswer(let saQuestion):
                    ShortAnswerQuestionView(question: question, questionWithSolution: saQuestion)
                @unknown default:
                    UnsupportedQuestionView(type: "\(question.quizQuestionWithSolutionDTO)")
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    var title: String? {
        switch question.quizQuestionWithSolutionDTO {
        case .dragAndDrop(let question): question.title
        case .multipleChoice(let question): question.title
        case .shortAnswer(let question): question.title
        }
    }
}

struct UnsupportedQuestionView: View {
    @Environment(QuizTrainingViewModel.self) private var viewModel

    let type: String?

    var body: some View {
        Text("Question type \(type ?? "") not supported.")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(R.string.localizable.skip()) {
                        viewModel.goToNextQuestion()
                    }
                }
            }
    }
}
