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
        if let first = conversationViewModel.offlineMessages.first {
            VStack(alignment: .leading) {
                Text("Offline")
                    .font(.headline)
                    .padding(.top, .m)
                    .padding(.horizontal, .l)
                Divider()
                    .padding(.horizontal, .l)
            }
            MessageCell(
                viewModel: conversationViewModel,
                message: Binding.constant(DataState<BaseMessage>.done(response: OfflineMessageOrAnswer(first))),
                conversationPath: nil,
                isHeaderVisible: true,
                retryButtonAction: viewModel.retryButtonAction
            )
            .task {
                await withTaskCancellationHandler {
                    await viewModel.sendMessage()
                } onCancel: {
                    log.verbose("cancel")
                }
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
}
