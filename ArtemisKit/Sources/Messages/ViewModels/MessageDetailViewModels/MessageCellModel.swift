//
//  MessageCellModel.swift
//
//
//  Created by Nityananda Zbil on 25.03.24.
//

import Foundation
import SharedModels

@MainActor
@Observable
final class MessageCellModel {
    let course: Course

    private let messagesService: MessagesService

    init(
        course: Course,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self.course = course
        self.messagesService = messagesService
    }

    func getOneToOneChatOrCreate(login: String) async -> Conversation? {
        async let conversations = messagesService.getConversations(for: course.id)
        async let chat = messagesService.createOneToOneChat(for: course.id, usernames: [login])

        if let conversations = await conversations.value,
           let conversation = conversations.first(where: { conversation in
                guard case let .oneToOneChat(conversation) = conversation,
                      let members = conversation.members else {
                    return false
                }
                return members.map(\.login).contains(login)
           }) {
            return conversation
        } else if let chat = await chat.value {
            return Conversation.oneToOneChat(conversation: chat)
        }

        return nil
    }
}
