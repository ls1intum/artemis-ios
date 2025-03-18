//
//  MessageActionsViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.03.25.
//

import Common
import Foundation
import Navigation
import SharedModels
import SwiftUI

@Observable
class MessageActionsViewModel {
    @ObservationIgnored @ObservedObject var conversationViewModel: ConversationViewModel
    @ObservationIgnored @Binding var message: DataState<BaseMessage>

    var showDeleteAlert = false
    @MainActor var canDelete: Bool {
        guard let message = message.value else {
            return false
        }

        if message.isCurrentUserAuthor {
            return true
        }

        guard let channel = conversationViewModel.conversation.baseConversation as? Channel else {
            return false
        }
        if channel.hasChannelModerationRights ?? false {
            return true
        }

        return false
    }

    var showEditSheet = false
    var canEdit: Bool {
        guard let message = message.value else {
            return false
        }

        if message.isCurrentUserAuthor {
            return true
        }

        return false
    }

    init(conversationViewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>) {
        self.conversationViewModel = conversationViewModel
        self._message = message
    }

    @MainActor
    func deleteMessage(navController: NavigationController) {
        conversationViewModel.isLoading = true
        Task(priority: .userInitiated) {
            let success: Bool
            let tempMessage = message.value
            if message.value is AnswerMessage {
                success = await conversationViewModel.deleteAnswerMessage(messageId: message.value?.id)
            } else {
                success = await conversationViewModel.deleteMessage(messageId: message.value?.id)
            }
            conversationViewModel.isLoading = false
            conversationViewModel.selectedMessageId = nil
            if success {
                // if we deleted a Message and are in the MessageDetailView we pop it
                if !navController.tabPath.isEmpty && tempMessage is Message {
                    navController.tabPath.removeLast()
                }
            }
        }
    }
}
