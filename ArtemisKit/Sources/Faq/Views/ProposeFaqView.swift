//
//  ProposeFaqView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 02.06.25.
//

import SwiftUI

struct ProposeFaqView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var viewModel: FaqViewModel

    var body: some View {
        NavigationStack {
            Form {
                // TODO: Localize
                Section("Question") {
                    TextField("Question", text: $viewModel.proposedFaq.questionTitle)
                }
                Section("Answer") {
                    TextField("Answer", text: $viewModel.proposedFaq.questionAnswer)
                }
                Section {
                    proposeButton
                }
            }
            .navigationTitle(R.string.localizable.proposeFaq())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(R.string.localizable.cancel()) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    proposeButton
                }
            }
        }
        .loadingIndicator(isLoading: $viewModel.isLoading)
    }

    var proposeButton: some View {
        Button(R.string.localizable.propose()) {
            Task {
                await viewModel.proposeFaq()
            }
        }
    }
}
