//
//  PathViewModels.swift
//
//
//  Created by Nityananda Zbil on 05.03.24.
//

import Combine
import Common
import Extensions
import Navigation
import SharedModels
import SharedServices
import SwiftUI
import UserStore

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

    private var subscription: AnyCancellable?

    init(path: ThreadPath) {
        self.path = path
        self.message = .loading

        subscribeToUpdates()
    }

    func loadMessage() async {
        let result = await MessagesServiceFactory.shared.getMessage(with: path.postId,
                                                                    for: path.coursePath.id,
                                                                    and: path.conversation.id)
        // Assigning directly does not work due to BaseMessage and Message not being the same
        switch result {
        case .loading:
            message = .loading
        case .failure(let error):
            message = .failure(error: error)
        case .done(let response):
            message = .done(response: response)
        }
    }

    /// Ensure we receive updates to the displayed message
    private func subscribeToUpdates() {
        let socketConnection = SocketConnectionHandler.shared
        subscription = socketConnection
            .messagePublisher
            .sink { [weak self] messageWebsocketDTO in
                guard let self else {
                    return
                }
                onMessageReceived(messageWebsocketDTO: messageWebsocketDTO)
            }

        if path.conversation.baseConversation.type == .channel,
           let channel = path.conversation.baseConversation as? Channel,
           channel.isCourseWide == true {
            socketConnection.subscribeToChannelNotifications(courseId: path.coursePath.id)
        } else if let id = UserSessionFactory.shared.user?.id {
            socketConnection.subscribeToConversationNotifications(userId: id)
        }
    }

    private func onMessageReceived(messageWebsocketDTO: MessageWebsocketDTO) {
        // Guard message corresponds to conversation
        guard messageWebsocketDTO.post.conversation?.id == path.conversation.id else {
            return
        }
        DispatchQueue.main.async {
            switch messageWebsocketDTO.action {
            case .update:
                self.handle(update: messageWebsocketDTO.post)
            case .delete:
                if messageWebsocketDTO.post.id == self.path.postId {
                    self.message = .loading
                }
            default:
                return
            }
        }
    }

    private func handle(update message: Message) {
        if message.id == path.postId, let oldMessage = self.message.value {
            // We do not get `authorRole` via websockets, thus we need to manually keep it
            var newMessage = message
            newMessage.authorRole = newMessage.authorRole ?? oldMessage.authorRole
            // Same for answers
            newMessage.answers = newMessage.answers?.map { answer in
                var newAnswer = answer
                let oldAnswer = (oldMessage as? Message)?.answers?.first { $0.id == answer.id }
                newAnswer.authorRole = newAnswer.authorRole ?? oldAnswer?.authorRole
                return newAnswer
            }
            self.message = .done(response: newMessage)
        }
    }
}
