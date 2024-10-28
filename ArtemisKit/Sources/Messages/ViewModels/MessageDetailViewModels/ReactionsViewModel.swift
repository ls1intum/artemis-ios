//
//  ReactionsViewModel.swift
//
//
//  Created by Anian Schleyer on 17.07.24.
//

import Common
import Foundation
import SharedModels
import Smile
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
            guard let emoji = Smile.emoji(alias: $0.emojiId) else {
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
        guard let emojiId = Smile.alias(emoji: emoji),
              let message = message.value else {
            return false
        }

        return message.containsReactionFromMe(emojiId: emojiId)
    }
}

// MARK: DataState<BaseMessage>+Equatable

/// We need conformance of DataState to Equatable for this ViewModel
/// to receive updates to `message` using SwiftUI's `onChange` modifier.
extension DataState<BaseMessage>: Equatable {
    public static func == (lhs: DataState<BaseMessage>, rhs: DataState<BaseMessage>) -> Bool {
        switch lhs {
        case .done(let responseLhs):
            switch rhs {
            case .done(let responseRhs):
                var hashLhs = Hasher()
                var hashRhs = Hasher()
                hashLhs.combine(responseLhs.id)
                hashRhs.combine(responseRhs.id)
                hashLhs.combine(responseLhs.author)
                hashRhs.combine(responseRhs.author)
                hashLhs.combine(responseLhs.reactions)
                hashRhs.combine(responseRhs.reactions)
                hashLhs.combine(responseLhs.updatedDate)
                hashRhs.combine(responseRhs.updatedDate)
                hashLhs.combine((responseLhs as? Message)?.displayPriority)
                hashRhs.combine((responseRhs as? Message)?.displayPriority)
                hashLhs.combine((responseLhs as? Message)?.resolved)
                hashRhs.combine((responseRhs as? Message)?.resolved)
                hashLhs.combine((responseLhs as? Message)?.answers)
                hashRhs.combine((responseRhs as? Message)?.answers)
                hashLhs.combine(responseLhs.content)
                hashRhs.combine(responseRhs.content)
                return hashLhs.finalize() == hashRhs.finalize()
            default:
                return false
            }
        default:
            return false
        }
    }
}
