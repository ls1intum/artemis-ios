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
        let message = OfflineMessageOrAnswer(viewModel.message)
        MessageCell(
            viewModel: conversationViewModel,
            message: Binding.constant(DataState<BaseMessage>.done(response: message)),
            conversationPath: nil,
            isHeaderVisible: !(viewModel.messageAhead.map { message.isContinuation(of: $0) } ?? false),
            retryButtonAction: viewModel.retryButtonAction
        )
        .task {
            try? await Task.sleep(for: .seconds(4))
            await viewModel.sendMessage()
        }
        .onDisappear {
            viewModel.task?.cancel()
        }
        ForEach(conversationViewModel.offlineMessages.dropFirst()) { offline in
            MessageCell(
                viewModel: conversationViewModel,
                message: Binding.constant(DataState<BaseMessage>.done(response: OfflineMessageOrAnswer(offline))),
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

            let messageAhead: Message?
            if let dailyMessages = conversationViewModel.dailyMessages.value,
               let max = dailyMessages.keys.max(),
               let dailyMessage = dailyMessages[max],
               let last = dailyMessage.last {
                messageAhead = last
            } else {
                messageAhead = nil
            }

            self.init(
                viewModel: ConversationOfflineSectionModel(
                    course: conversationViewModel.course,
                    conversation: conversationViewModel.conversation,
                    messageAhead: messageAhead,
                    message: message,
                    messageQueue: messageQueue,
                    delegate: ConversationOfflineSectionModelDelegate(conversationViewModel)),
                conversationViewModel: conversationViewModel)
        } else {
            return nil
        }
    }
}
