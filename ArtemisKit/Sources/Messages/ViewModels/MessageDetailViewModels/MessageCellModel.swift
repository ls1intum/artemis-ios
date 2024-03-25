//
//  MessageCellModel.swift
//
//
//  Created by Nityananda Zbil on 25.03.24.
//

import Foundation
import Navigation
import SharedModels
import UserStore

@MainActor
@Observable
final class MessageCellModel {
    let course: Course

    let conversationPath: ConversationPath?
    let isHeaderVisible: Bool
    let retryButtonAction: (() -> Void)?

    var isActionSheetPresented = false
    var isDetectingLongPress = false

    private let messagesService: MessagesService
    private let userSession: UserSession

    init(
        course: Course,
        conversationPath: ConversationPath?,
        isHeaderVisible: Bool,
        retryButtonAction: (() -> Void)?,
        messagesService: MessagesService = MessagesServiceFactory.shared,
        userSession: UserSession = .shared
    ) {
        self.course = course
        self.conversationPath = conversationPath
        self.isHeaderVisible = isHeaderVisible
        self.retryButtonAction = retryButtonAction
        self.messagesService = messagesService
        self.userSession = userSession
    }
}

extension MessageCellModel {
    // MARK: View

    func isChipVisible(creationDate: Date, authorId: Int64?) -> Bool {
        guard let lastReadDate = conversationPath?.conversation?.baseConversation.lastReadDate else {
            return false
        }

        return lastReadDate < creationDate && userSession.user?.id != authorId
    }

    // MARK: Navigation

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
