//
//  File.swift
//  
//
//  Created by Nityananda Zbil on 09.10.23.
//

import Foundation
import Common
import APIClient
import SharedModels
import UserStore
@testable import Messages

struct MessagesServiceStub: MessagesService {

    private static let me = ConversationUser(
        id: 1,
        name: "Me")

    private static let ethan = ConversationUser(
        id: 2,
        name: "Ethan Martin",
        isRequestingUser: false)

    private static let sophia = ConversationUser(
        id: 3,
        name: "Sophia Davis",
        isRequestingUser: false)

    private static let channel1 = Conversation(
        conversation: Channel(
            type: .channel,
            id: 2,
            unreadMessagesCount: 8,
            name: "General Course Questions"))!

    private static let channel2 = Conversation(
        conversation: Channel(
            type: .channel,
            id: 3,
            unreadMessagesCount: 17,
            name: "Designing a rocket engine - Q&A"))!

    private static let groupChat = Conversation(
        conversation: GroupChat(
            type: .groupChat,
            id: 4,
            name: "Team Rocket Students"))!

    private static let oneToOneChat1 = Conversation(
        conversation: OneToOneChat(
            type: .oneToOneChat,
            id: 1,
            members: [
                ethan,
                me,
            ]))!

    private static let oneToOneChat2 = Conversation(
        conversation: OneToOneChat(
            type: .oneToOneChat, 
            id: 5,
            unreadMessagesCount: 3,
            members: [
                sophia,
                me,
            ]))!

    private static let messages = [
        Message(
            id: 1,
            author: me,
            creationDate: .now,
            content: "Do you know the difference between `&` and `&&`?"),
        Message(
            id: 2,
            author: ethan,
            creationDate: .now.advanced(by: 1),
            updatedDate: .now.advanced(by: 2),
            // swiftlint:disable:next line_length
            content: "Sure, `&` is a **bitwise** operator, and `&&` represents the logical _AND_. By the way \n> If either value is false, the overall expression will also be false. In fact, if the first value is false, the second value won’t even be evaluated, because it can’t possibly make the overall expression equate to true. This is known as short-circuit evaluation.",
            reactions: [
                Reaction(id: 1,
                      creationDate: .now.advanced(by: 2),
                      emojiId: "+1"),
                Reaction(id: 2,
                      creationDate: .now.advanced(by: 3),
                      emojiId: "mindblown"),
            ]),
        Message(
            id: 3,
            author: me,
            creationDate: .now.advanced(by: 4),
            content: "Thanks!",
            reactions: [
                Reaction(id: 3,
                      creationDate: .now.advanced(by: 5),
                      emojiId: "relaxed")
            ]),
    ]

    func getConversations(for courseId: Int) async -> Common.DataState<[SharedModels.Conversation]> {
        .done(response: [Self.channel1, Self.channel2, Self.groupChat, Self.oneToOneChat1, Self.oneToOneChat2])
    }

    func hideUnhideConversation(for courseId: Int, and conversationId: Int64, isHidden: Bool) async -> Common.NetworkResponse {
        .loading
    }

    func setIsFavoriteConversation(for courseId: Int, and conversationId: Int64, isFavorite: Bool) async -> Common.NetworkResponse {
        .loading
    }

    func getMessages(for courseId: Int, and conversationId: Int64, size: Int) async -> Common.DataState<[SharedModels.Message]> {
        .done(response: Self.messages)
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
        .done(response: [])
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
        fatalError()
    }

    func searchForUsers(for courseId: Int, searchText: String) async -> Common.DataState<[SharedModels.ConversationUser]> {
        .done(response: [])
    }

    func createGroupChat(for courseId: Int, usernames: [String]) async -> Common.DataState<SharedModels.GroupChat> {
        fatalError()
    }

    func createOneToOneChat(for courseId: Int, usernames: [String]) async -> Common.DataState<SharedModels.OneToOneChat> {
        fatalError()
    }

    func getMembersOfConversation(for courseId: Int, conversationId: Int64, page: Int) async -> Common.DataState<[SharedModels.ConversationUser]> {
        .done(response: [])
    }

    func archiveChannel(for courseId: Int, channelId: Int64) async -> Common.NetworkResponse {
        .loading
    }

    func unarchiveChannel(for courseId: Int, channelId: Int64) async -> Common.NetworkResponse {
        .loading
    }
}
