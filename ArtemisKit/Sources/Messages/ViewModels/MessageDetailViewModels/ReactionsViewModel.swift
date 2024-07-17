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
    private var message: Binding<DataState<BaseMessage>>

    init(conversationViewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>) {
        self.conversationViewModel = conversationViewModel
        self.message = message
    }

    // We need to explicitly pass message to this, otherwise it will not update
    func mappedReaction(message: DataState<BaseMessage>) -> [String: [Reaction]] {
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
        if let message = message.wrappedValue.value as? Message {
            let result = await conversationViewModel.addReactionToMessage(for: message, emojiId: emojiId)
            switch result {
            case .loading:
                self.message.wrappedValue = .loading
            case .failure(let error):
                self.message.wrappedValue = .failure(error: error)
            case .done(let response):
                self.message.wrappedValue = .done(response: response)
            }
        } else if let answerMessage = message.wrappedValue.value as? AnswerMessage {
            let result = await conversationViewModel.addReactionToAnswerMessage(for: answerMessage, emojiId: emojiId)
            switch result {
            case .loading:
                self.message.wrappedValue = .loading
            case .failure(let error):
                self.message.wrappedValue = .failure(error: error)
            case .done(let response):
                self.message.wrappedValue = .done(response: response)
            }
        }
    }
}
