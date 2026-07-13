//
//  SubmitLiveAnswerButton.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.06.26.
//

import DesignLibrary
import SharedModels
import SwiftUI

struct SubmitLiveAnswerButton: View {
    @Environment(QuizParticipationViewModel.self) private var viewModel

    let answer: DTO.SubmittedAnswerFromLiveClient

    @State private var isLoading = false

    var body: some View {
        Spacer()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        submit()
                    } label: {
                        Text(R.string.localizable.submit())
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(isLoading)
                    .loadingIndicator(isLoading: $isLoading)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        viewModel.saveAnswer(answer)
                        viewModel.previousQuestion()
                    } label: {
                        Text("Previous question") // TODO: Localize
                    }

                    Button {
                        viewModel.saveAnswer(answer)
                        viewModel.nextQuestion()
                    } label: {
                        Text(R.string.localizable.nextQuestion())
                    }
                }
            }
            .alert(R.string.localizable.failedToSubmit(), isPresented: .init(
                get: {
                    if let success = viewModel.submissionSuccessful, !success {
                        return true
                    } else {
                        return false
                    }
                }, set: { newValue in
                    if !newValue {
                        viewModel.submissionSuccessful = nil
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
            await viewModel.submit()
            isLoading = false
        }
    }
}
