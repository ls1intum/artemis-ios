//
//  OfflineMessageCell.swift
//
//
//  Created by Nityananda Zbil on 08.03.24.
//

import Common
import SharedModels
import SwiftUI

struct OfflineMessageCell: View {
    let viewModel: OfflineMessageCellModel
    let conversationViewModel: ConversationViewModel

    var body: some View {
        MessageCell(
            viewModel: conversationViewModel,
            message: Binding.constant(DataState<BaseMessage>.done(response: OfflineMessageOrAnswer(viewModel.message))),
            conversationPath: nil,
            isHeaderVisible: true,
            retryButtonAction: viewModel.retryButtonAction
        )
        .task {
            await viewModel.sendMessage()
        }
        .onDisappear {
            viewModel.task?.cancel()
        }
    }
}
