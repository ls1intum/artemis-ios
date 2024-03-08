//
//  ConversationOfflineMessageCell.swift
//
//
//  Created by Nityananda Zbil on 08.03.24.
//

import Common
import Navigation
import SharedModels
import SwiftUI

struct ConversationOfflineMessageCell: View {
    let viewModel: ConversationViewModel
    @State var message: ConversationOfflineMessageModel

    var body: some View {
        MessageCell(
            viewModel: viewModel,
            message: Binding.constant(DataState<BaseMessage>.done(response: ConversationOfflineMessage(message))),
            conversationPath: ConversationPath?.none,
            isHeaderVisible: true,
            retryButtonAction: {
                //
            })
    }
}
