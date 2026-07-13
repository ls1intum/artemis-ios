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
            .alert(viewModel.batchStartError ?? "Could not join batch",
                   isPresented: Binding {
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
