//
//  PathViewModels.swift
//
//
//  Created by Nityananda Zbil on 05.03.24.
//

import Common
import Extensions
import Navigation
import SharedModels
import SharedServices
import SwiftUI

@Observable
final class ConversationPathViewModel {
    let path: ConversationPath
    var conversation: DataState<Conversation>

    private let messagesService: MessagesService

    init(path: ConversationPath, messagesService: MessagesService = MessagesServiceFactory.shared) {
        self.path = path
        self.conversation = path.conversation.map(DataState.done) ?? .loading

        self.messagesService = messagesService
    }

    func reloadConversation() async {
        let result = await messagesService.getConversations(for: path.coursePath.id)
        self.conversation = result.flatMap { conversations in
            if let conversation = conversations.first(where: { $0.id == path.id }) {
                return .success(conversation)
            } else {
                return .failure(UserFacingError(title: R.string.localizable.conversationNotLoaded()))
            }
        }
    }

    func loadConversation() async {
        // If conversation is loaded already, skip
        switch conversation {
        case .done:
            return
        default:
            break
        }
        await reloadConversation()
    }
}

@Observable
final class ThreadPathViewModel {
    let path: ThreadPath
    var message: DataState<BaseMessage>

    private let messagesService: MessagesService

    init(path: ThreadPath, messagesService: MessagesService = MessagesServiceFactory.shared) {
        self.path = path
        self.message = .loading

        self.messagesService = messagesService
    }

    func loadMessage() async {
        let result = await messagesService.getMessage(with: path.postId, for: path.coursePath.id, and: path.conversation.id)
        switch result {
        case .loading:
            message = .loading
        case .failure(let error):
            message = .failure(error: error)
        case .done(let response):
            message = .done(response: response)
        }
    }
}
