//
//  ConversationOfflineSection.swift
//
//
//  Created by Nityananda Zbil on 10.03.24.
//

import SwiftUI

struct ConversationOfflineSection: View {
    @ObservedObject var viewModel: ConversationViewModel

    var body: some View {
        if !viewModel.offlineMessages.isEmpty {
            VStack(alignment: .leading) {
                Text("Offline")
                    .font(.headline)
                    .padding(.top, .m)
                    .padding(.horizontal, .l)
                Divider()
                    .padding(.horizontal, .l)
            }
            ForEach(viewModel.offlineMessages) { offline in
                OfflineMessageCell(
                    viewModel: OfflineMessageCellModel(
                        course: viewModel.course,
                        conversation: viewModel.conversation,
                        message: offline,
                        delegate: OfflineMessageCellModelDelegate(viewModel)),
                    conversationViewModel: viewModel)
            }
        }
    }
}
