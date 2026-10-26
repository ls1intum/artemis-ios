//
//  ReactionsViewModel.swift
//
//
//  Created by Anian Schleyer on 17.07.24.
//

import Common
import Foundation
import SharedModels
import SwiftUI

@Observable
class ReactionsViewModel {
    private var conversationViewModel: ConversationViewModel
    var showAuthorsSheet = false
    var selectedReactionSheet = "All"

    // Binding to pass updates back to ConversationViewModel
    private var messageBinding: Binding<DataState<BaseMessage>>
    // Regular variable to take advantage of automatic Observable updates
    var message: DataState<BaseMessage>

    init(conversationViewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>) {
        self.conversationViewModel = conversationViewModel
        self.messageBinding = message
        self.message = message.wrappedValue
    }

    var mappedReaction: [String: [Reaction]] {
        var reactions = [String: [Reaction]]()

        message.value?.reactions?.forEach {
            guard let emoji = Emojis.getEmoji(for: $0.emojiId) else {
                return
            }
            if reactions[emoji] != nil {
                reactions[emoji]?.append($0)
            } else {
                reactions[emoji] = [$0]
            }
        }
        return reactions
    }

    @MainActor
    func addReaction(emojiId: String) async {
        if let message = message.value as? Message {
            let result = await conversationViewModel.addReactionToMessage(for: message, emojiId: emojiId)
            switch result {
            case .loading:
                self.messageBinding.wrappedValue = .loading
            case .failure(let error):
                self.messageBinding.wrappedValue = .failure(error: error)
            case .done(let response):
                self.messageBinding.wrappedValue = .done(response: response)
            }
        } else if let answerMessage = message.value as? AnswerMessage {
            let result = await conversationViewModel.addReactionToAnswerMessage(for: answerMessage, emojiId: emojiId)
            switch result {
            case .loading:
                self.messageBinding.wrappedValue = .loading
            case .failure(let error):
                self.messageBinding.wrappedValue = .failure(error: error)
            case .done(let response):
                self.messageBinding.wrappedValue = .done(response: response)
            }
        }
        conversationViewModel.selectedMessageId = nil
    }

    func isMyReaction(_ emoji: String) -> Bool {
        guard let emojiId = Emojis.getEmojiId(for: emoji),
              let message = message.value else {
            return false
        }

        return message.containsReactionFromMe(emojiId: emojiId)
    }
}
