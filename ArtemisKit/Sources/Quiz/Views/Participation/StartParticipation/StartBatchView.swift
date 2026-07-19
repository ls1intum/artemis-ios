//
//  StartBatchView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 13.07.26.
//

import DesignLibrary
import SwiftUI

struct StartBatchView: View {
    @Environment(QuizParticipationViewModel.self) private var viewModel
    let isIndividual: Bool
    @State private var password = ""
    @State private var loading = false
    @State private var showWaitingScreen = false

    var body: some View {
        if showWaitingScreen {
            WaitForQuizStartView(viewModel: viewModel)
        } else {
            // TODO: Style + Localize
            Form {
                if !isIndividual {
                    Section("Password") {
                        TextField("Password", text: $password)
                    }
                }

                Button("Join Quiz") {
                    startBatch()
                }
                .disabled(loading)
                .loadingIndicator(isLoading: $loading)
            }
            .onAppear {
                // Existing batch that user has joined -> wait automatically
                if let party = viewModel.participation.value,
                   case let .StudentQuizParticipationWithSolutions(withSolutions) = party,
                   let batches = withSolutions.exercise?.quizBatches,
                   let notStarted = batches.last(where: { $0.started != true })?.id {
                    viewModel.startWaitingForBatchStart(batchId: Int64(notStarted))
                    showWaitingScreen = true
                }
            }
            .alert(viewModel.batchStartError ?? "Could not join batch", isPresented: Binding {
                viewModel.batchStartError != nil
            } set: { newValue in
                if !newValue {
                    viewModel.batchStartError = nil
                }
            }) {
                Button("Ok") {}
                Button(R.string.localizable.retry()) {
                    startBatch()
                }
            }
        }
    }

    func startBatch() {
        loading = true
        Task {
            await viewModel.joinBatch(password: password)
            loading = false
            if viewModel.batchStartError == nil {
                showWaitingScreen = true
            }
        }
    }
}
