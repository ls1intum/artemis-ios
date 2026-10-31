//
//  File.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.03.25.
//

import SharedModels
import SwiftUI

struct EditMessageView: View {
    let viewModel: MessageActionsViewModel

    private var editDelegate: SendMessageViewModelDelegate {
        var delegate = SendMessageViewModelDelegate(viewModel.conversationViewModel)
        delegate.didEditMessage = { updated in
            if let merged = MessageActionsViewModel.mergeAcceptedEdit(updated, into: viewModel.message.value) {
                viewModel.message = .done(response: merged)
            }
        }
        return delegate
    }

    var body: some View {
        NavigationView {
            Group {
                if let message = viewModel.message.value as? Message {
                    SendMessageView(
                        viewModel: SendMessageViewModel(
                            course: viewModel.conversationViewModel.course,
                            conversation: viewModel.conversationViewModel.conversation,
                            configuration: .editMessage(message, { viewModel.showEditSheet = false }),
                            delegate: editDelegate
                        )
                    )
                } else if let answerMessage = viewModel.message.value as? AnswerMessage {
                    SendMessageView(
                        viewModel: SendMessageViewModel(
                            course: viewModel.conversationViewModel.course,
                            conversation: viewModel.conversationViewModel.conversation,
                            configuration: .editAnswerMessage(answerMessage, { viewModel.showEditSheet = false }),
                            delegate: editDelegate
                        )
                    )
                } else {
                    Text(R.string.localizable.loading())
                }
            }
            .navigationTitle(R.string.localizable.editMessage())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(R.string.localizable.cancel()) {
                        viewModel.showEditSheet = false
                    }
                }
            }
        }
        .fontWeight(.regular)
        .presentationDetents([.medium, .large])
    }
}
