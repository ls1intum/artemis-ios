//
//  ConversationOfflineSection.swift
//
//
//  Created by Nityananda Zbil on 10.03.24.
//

import Common
import SharedModels
import SwiftUI

struct ConversationOfflineSection: View {
    @State var viewModel: ConversationOfflineSectionModel
    @ObservedObject var conversationViewModel: ConversationViewModel

    var body: some View {
        MessageCell(
            viewModel: conversationViewModel,
            message: Binding.constant(DataState<BaseMessage>.done(response: OfflineMessageOrAnswer(viewModel.message))),
            conversationPath: nil,
            isHeaderVisible: viewModel.taskDidFail,
            retryButtonAction: viewModel.retryButtonAction
        )
        .task {
            await viewModel.sendMessage()
        }
        .onDisappear {
            viewModel.task?.cancel()
        }
        ForEach(viewModel.messageQueue) { message in
            MessageCell(
                viewModel: conversationViewModel,
                message: Binding.constant(DataState<BaseMessage>.done(response: OfflineMessageOrAnswer(message))),
                conversationPath: nil,
                isHeaderVisible: false
            )
        }
    }
}

extension ConversationOfflineSection {
    init?(_ conversationViewModel: ConversationViewModel) {
        if let message = conversationViewModel.offlineMessages.first {
            let messageQueue = conversationViewModel.offlineMessages.dropFirst()

            self.init(
                viewModel: ConversationOfflineSectionModel(
                    course: conversationViewModel.course,
                    conversation: conversationViewModel.conversation,
                    message: message,
                    messageQueue: messageQueue,
                    delegate: ConversationOfflineSectionModelDelegate(conversationViewModel)),
                conversationViewModel: conversationViewModel)
        } else {
            return nil
        }
    }
}
