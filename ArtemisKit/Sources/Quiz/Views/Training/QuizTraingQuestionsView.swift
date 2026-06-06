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
            }
        }
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
                if let title = question.quizQuestionWithSolutionDTO.title {
                    Text(title)
                        .font(.title)
                        .padding(.horizontal)
                }

                switch question.quizQuestionWithSolutionDTO._type {
                case "multiple-choice": MCQuestionView(question: question)
                case "drag-and-drop": UnsupportedQuestionView(type: question.quizQuestionWithSolutionDTO._type)
                case "short-answer": UnsupportedQuestionView(type: question.quizQuestionWithSolutionDTO._type)
                default: UnsupportedQuestionView(type: question.quizQuestionWithSolutionDTO._type)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
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
                    Button("Skip") {
                        viewModel.goToNextQuestion()
                    }
                }
            }
    }
}
