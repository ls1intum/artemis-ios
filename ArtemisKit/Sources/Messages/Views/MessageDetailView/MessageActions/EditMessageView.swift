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

    var body: some View {
        NavigationView {
            Group {
                if let message = viewModel.message.value as? Message {
                    SendMessageView(
                        viewModel: SendMessageViewModel(
                            course: viewModel.conversationViewModel.course,
                            conversation: viewModel.conversationViewModel.conversation,
                            configuration: .editMessage(message, { viewModel.showEditSheet = false }),
                            delegate: SendMessageViewModelDelegate(viewModel.conversationViewModel)
                        )
                    )
                } else if let answerMessage = viewModel.message.value as? AnswerMessage {
                    SendMessageView(
                        viewModel: SendMessageViewModel(
                            course: viewModel.conversationViewModel.course,
                            conversation: viewModel.conversationViewModel.conversation,
                            configuration: .editAnswerMessage(answerMessage, { viewModel.showEditSheet = false }),
                            delegate: SendMessageViewModelDelegate(viewModel.conversationViewModel)
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
        .presentationDetents([.height(200), .medium])
    }
}
