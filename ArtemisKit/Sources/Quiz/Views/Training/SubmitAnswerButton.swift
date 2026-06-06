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
        Button("Submit") {
            submit()
        }
        .disabled(isLoading)
        .loadingIndicator(isLoading: $isLoading)
        .alert("Failed to submit answer", isPresented: .init(
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
            Button("Retry") {
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
