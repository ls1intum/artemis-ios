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

    @FocusState private var focused

    var body: some View {
        if showWaitingScreen {
            WaitForQuizStartView(viewModel: viewModel)
        } else {
            VStack(alignment: .center, spacing: .l) {
                Text(isIndividual ? R.string.localizable.startParticipation() : R.string.localizable.enterPassword())
                    .font(.title2)

                if !isIndividual {
                    TextField(R.string.localizable.password(), text: $password)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.go)
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .onAppear {
                            focused = true
                        }
                }

                Button(R.string.localizable.joinQuiz()) {
                    focused = false
                    startBatch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(loading || !isIndividual && password.isEmpty)
                .loadingIndicator(isLoading: $loading)
            }
            .padding()
            .background(Color.Artemis.artemisBlue.opacity(0.5), in: .rect(cornerRadius: .l))
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .onAppear {
                // Existing batch that user has joined -> wait automatically
                if let batches = viewModel.participation.value?.quizBatches,
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
            await viewModel.joinBatch(password: password.isEmpty ? nil : password)
            loading = false
            if viewModel.batchStartError == nil {
                showWaitingScreen = true
            }
        }
    }
}
