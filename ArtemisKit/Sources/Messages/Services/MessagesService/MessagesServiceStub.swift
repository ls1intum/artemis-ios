//
//  MessagesServiceStub.swift
//
//
//  Created by Nityananda Zbil on 14.02.24.
//

import Common
import Foundation
import SharedModels

struct MessagesServiceStub {
    static let now: Date = {
        // swiftlint:disable:next force_try
        try! Date("2024-01-08T9:41:32Z", strategy: .iso8601)
    }()

    static let course: Course = {
        let course = Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)
        return course
    }()

    static let conversation: Conversation = {
        var oneToOneChat = OneToOneChat(id: 1)
        oneToOneChat.lastReadDate = now
        let conversation = Conversation.oneToOneChat(conversation: oneToOneChat)
        return conversation
    }()

    static let alice: ConversationUser = {
        var author = ConversationUser(id: 1)
        author.name = "Alice"
        return author
    }()

    static let bob: ConversationUser = {
        var author = ConversationUser(id: 2)
        author.name = "Bob"
        return author
    }()

    static let message: Message = {
        var message = Message(id: 1)
        message.author = alice
        message.creationDate = Calendar.current.date(byAdding: .minute, value: 1, to: now)

        message.content = "Hello, world!"

        message.updatedDate = Calendar.current.date(byAdding: .minute, value: 2, to: now)

        message.reactions = [
            Reaction(id: 1),
            Reaction(id: 2),
            Reaction(id: 3, emojiId: "heart")
        ]

        message.answers = [
            AnswerMessage(id: 2),
            AnswerMessage(id: 3),
            AnswerMessage(id: 4)
        ]

        return message
    }()

    let messages: [Message]
}

extension MessagesServiceStub: MessagesService {
    func getConversations(for courseId: Int) async -> Common.DataState<[SharedModels.Conversation]> {
        .loading
    }

    func updateIsConversationFavorite(for courseId: Int, and conversationId: Int64, isFavorite: Bool) async -> NetworkResponse {
        .loading
    }

    func updateIsConversationMuted(for courseId: Int, and conversationId: Int64, isMuted: Bool) async -> NetworkResponse {
        .loading
    }

    func updateIsConversationHidden(for courseId: Int, and conversationId: Int64, isHidden: Bool) async -> NetworkResponse {
        .loading
    }

    func getMessages(for courseId: Int, and conversationId: Int64, size: Int) async -> Common.DataState<[SharedModels.Message]> {
        .done(response: messages)
    }

    func sendMessage(for courseId: Int, conversation: SharedModels.Conversation, content: String) async -> Common.NetworkResponse {
        .loading
    }

    func sendAnswerMessage(for courseId: Int, message: SharedModels.Message, content: String) async -> Common.NetworkResponse {
        .loading
    }

    func deleteMessage(for courseId: Int, messageId: Int64) async -> Common.NetworkResponse {
        .loading
    }

    func deleteAnswerMessage(for courseId: Int, anserMessageId: Int64) async -> Common.NetworkResponse {
        .loading
    }

    func editMessage(for courseId: Int, message: SharedModels.Message) async -> Common.NetworkResponse {
        .loading
    }

    func editAnswerMessage(for courseId: Int, answerMessage: SharedModels.AnswerMessage) async -> Common.NetworkResponse {
        .loading
    }

    func addReactionToAnswerMessage(for courseId: Int, answerMessage: SharedModels.AnswerMessage, emojiId: String) async -> Common.NetworkResponse {
        .loading
    }

    func addReactionToMessage(for courseId: Int, message: SharedModels.Message, emojiId: String) async -> Common.NetworkResponse {
        .loading
    }

    func removeReactionFromMessage(for courseId: Int, reaction: SharedModels.Reaction) async -> Common.NetworkResponse {
        .loading
    }

    func getChannelsOverview(for courseId: Int) async -> Common.DataState<[SharedModels.Channel]> {
        .loading
    }

    func addMembersToChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> Common.NetworkResponse {
        .loading
    }

    func removeMembersFromChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> Common.NetworkResponse {
        .loading
    }

    func addMembersToGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> Common.NetworkResponse {
        .loading
    }

    func removeMembersFromGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> Common.NetworkResponse {
        .loading
    }

    func createChannel(for courseId: Int, name: String, description: String?, isPrivate: Bool, isAnnouncement: Bool) async -> Common.DataState<SharedModels.Channel> {
        .loading
    }

    func searchForUsers(for courseId: Int, searchText: String) async -> Common.DataState<[SharedModels.ConversationUser]> {
        .loading
    }

    func createGroupChat(for courseId: Int, usernames: [String]) async -> Common.DataState<SharedModels.GroupChat> {
        .loading
    }

    func createOneToOneChat(for courseId: Int, usernames: [String]) async -> Common.DataState<SharedModels.OneToOneChat> {
        .loading
    }

    func getMembersOfConversation(for courseId: Int, conversationId: Int64, page: Int) async -> Common.DataState<[SharedModels.ConversationUser]> {
        .loading
    }

    func archiveChannel(for courseId: Int, channelId: Int64) async -> Common.NetworkResponse {
        .loading
    }

    func unarchiveChannel(for courseId: Int, channelId: Int64) async -> Common.NetworkResponse {
        .loading
    }
}
