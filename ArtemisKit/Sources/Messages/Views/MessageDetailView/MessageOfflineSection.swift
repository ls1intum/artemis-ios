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
