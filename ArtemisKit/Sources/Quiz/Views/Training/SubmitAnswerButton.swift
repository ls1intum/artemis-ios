//
//  SubmitAnswerButton.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.06.26.
//

import DesignLibrary
import SharedModels
import SwiftUI

struct SubmitAnswerButton: View {
    @Environment(QuizTrainingViewModel.self) private var viewModel

    let questionId: Int64?
    let isRated: Bool?
    let answer: QuizTrainingAnswer

    @State private var isLoading = false

    var body: some View {
        Button {
            if case .done = viewModel.lastSubmissionResult {
                viewModel.goToNextQuestion()
            } else {
                submit()
            }
        } label: {
            if case .done = viewModel.lastSubmissionResult {
                Text(R.string.localizable.nextQuestion())
            } else {
                Text(R.string.localizable.submit())
            }
        }
        .disabled(isLoading)
        .loadingIndicator(isLoading: $isLoading)
        .alert(R.string.localizable.failedToSubmit(), isPresented: .init(
            get: {
                if case .failure = viewModel.lastSubmissionResult {
                    return true
                } else {
                    return false
                }
            }, set: { newValue in
                if !newValue {
                    viewModel.lastSubmissionResult = .loading
                }
            })
        ) {
            Button("Ok") {}
            Button(R.string.localizable.retry()) {
                submit()
            }
        }
    }

    func submit() {
        isLoading = true
        Task {
            await viewModel.submitAnswer(questionId: questionId ?? -1,
                                         isRated: isRated ?? false,
                                         answer: answer)
            isLoading = false
        }
    }
}
