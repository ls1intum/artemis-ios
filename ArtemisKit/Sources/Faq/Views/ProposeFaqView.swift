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
                Section(R.string.localizable.question()) {
                    TextField(R.string.localizable.question(), text: $viewModel.proposedFaq.questionTitle)
                }
                Section(R.string.localizable.answer()) {
                    TextField(R.string.localizable.answer(), text: $viewModel.proposedFaq.questionAnswer)
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
        .alert(viewModel.error?.title ?? "An error occurred", isPresented: Binding<Bool>(get: {
            viewModel.error != nil
        }, set: { newValue in
            if newValue == false {
                viewModel.error = nil
            }
        })) {}
    }

    var proposeButton: some View {
        Button(R.string.localizable.propose()) {
            Task {
                await viewModel.proposeFaq()
            }
        }
    }
}
