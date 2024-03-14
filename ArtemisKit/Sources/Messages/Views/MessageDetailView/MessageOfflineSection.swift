//
//  MessageOfflineSection.swift
//
//
//  Created by Nityananda Zbil on 13.03.24.
//

import Common
import SharedModels
import SwiftUI

struct MessageOfflineSection: View {
    @State var viewModel: MessageOfflineSectionModel
    @ObservedObject var conversationViewModel: ConversationViewModel

    var body: some View {
        Group {
            MessageCell(
                viewModel: conversationViewModel,
                message: Binding.constant(DataState<BaseMessage>.done(response: OfflineMessageOrAnswer(viewModel.answer))),
                conversationPath: nil,
                isHeaderVisible: viewModel.taskDidFail,
                retryButtonAction: viewModel.retryButtonAction
            )
            .task {
                await viewModel.sendAnswer()
            }
            .onDisappear {
                viewModel.task?.cancel()
            }
            ForEach(viewModel.answerQueue) { answer in
                MessageCell(
                    viewModel: conversationViewModel,
                    message: Binding.constant(DataState<BaseMessage>.done(response: OfflineMessageOrAnswer(answer))),
                    conversationPath: nil,
                    isHeaderVisible: false
                )
            }
        }
        .environment(\.isMessageOffline, true)
    }
}

extension MessageOfflineSection {
    init?(_ messageDetailViewModel: MessageDetailViewModel, conversationViewModel: ConversationViewModel) {
        if let answer = messageDetailViewModel.offlineAnswers.first {
            let answerQueue = messageDetailViewModel.offlineAnswers.dropFirst()

            self.init(
                viewModel: MessageOfflineSectionModel(
                    course: messageDetailViewModel.course,
                    conversation: messageDetailViewModel.conversation,
                    message: messageDetailViewModel.message,
                    answer: answer, 
                    answerQueue: answerQueue,
                    delegate: MessageOfflineSectionModelDelegate(messageDetailViewModel)),
                conversationViewModel: conversationViewModel)
        } else {
            return nil
        }
    }
}
