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

    static let charlie: ConversationUser = {
        var author = ConversationUser(id: 3)
        author.name = "Charlie"
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

        message.answers = [answer]

        return message
    }()

    static let answer: AnswerMessage = {
        var answer = AnswerMessage(id: 2)
        answer.author = bob
        answer.creationDate = Calendar.current.date(byAdding: .minute, value: 3, to: now)
        answer.content = "Hello, Alice!"
        return answer
    }()

    static let continuation: Message = {
        var message = Message(id: 3)
        message.author = alice
        message.creationDate = Calendar.current.date(byAdding: .minute, value: 4, to: now)
        message.content = "How are you?"
        return message
    }()

    static let reply: Message = {
        var message = Message(id: 4)
        message.author = bob
        message.creationDate = Calendar.current.date(byAdding: .minute, value: 4, to: now)
        message.content = "I am great."
        return message
    }()

    var messages: [Message] = [message, continuation, reply]
}

extension MessagesServiceStub: MessagesService {
    func getConversations(for courseId: Int) async -> DataState<[Conversation]> {
        .done(response: [.channel(conversation: .mock)])
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

    func getMessages(for courseId: Int, and conversationId: Int64, filter: MessageRequestFilter, page: Int) async -> DataState<[Message]> {
        .done(response: messages)
    }

    func getMessage(with messageId: Int64, for courseId: Int, and conversationId: Int64) async -> DataState<Message> {
        .loading
    }

    func sendMessage(for courseId: Int, conversation: Conversation, content: String) async -> NetworkResponse {
        .loading
    }

    func sendAnswerMessage(for courseId: Int, message: Message, content: String) async -> NetworkResponse {
        .loading
    }

    func deleteMessage(for courseId: Int, messageId: Int64) async -> NetworkResponse {
        .loading
    }

    func deleteAnswerMessage(for courseId: Int, anserMessageId: Int64) async -> NetworkResponse {
        .loading
    }

    func editMessage(for courseId: Int, message: Message) async -> NetworkResponse {
        .loading
    }

    func updateMessageDisplayPriority(for courseId: Int64, messageId: Int64, displayPriority: DisplayPriority) async -> DataState<any BaseMessage> {
        .loading
    }

    func editAnswerMessage(for courseId: Int, answerMessage: AnswerMessage) async -> NetworkResponse {
        .loading
    }

    func addReactionToAnswerMessage(for courseId: Int, answerMessage: AnswerMessage, emojiId: String) async -> NetworkResponse {
        .loading
    }

    func addReactionToMessage(for courseId: Int, message: Message, emojiId: String) async -> NetworkResponse {
        .loading
    }

    func removeReactionFromMessage(for courseId: Int, reaction: Reaction) async -> NetworkResponse {
        .loading
    }

    func getChannelsOverview(for courseId: Int) async -> DataState<[Channel]> {
        .loading
    }

    func getChannelsPublicOverview(for courseId: Int) async -> DataState<[ChannelIdAndNameDTO]> {
        .done(response: [ChannelIdAndNameDTO(id: 2, name: "announcement")])
    }

    func addMembersToChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> NetworkResponse {
        .loading
    }

    func removeMembersFromChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> NetworkResponse {
        .loading
    }

    func addMembersToGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> NetworkResponse {
        .loading
    }

    func removeMembersFromGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> NetworkResponse {
        .loading
    }

    func createChannel(for courseId: Int, name: String, description: String?, isPrivate: Bool, isAnnouncement: Bool, isCourseWide: Bool) async -> DataState<Channel> {
        .loading
    }

    func searchForUsers(for courseId: Int, searchText: String) async -> DataState<[ConversationUser]> {
        .loading
    }

    func createGroupChat(for courseId: Int, usernames: [String]) async -> DataState<GroupChat> {
        .loading
    }

    func createOneToOneChat(for courseId: Int, usernames: [String]) async -> DataState<OneToOneChat> {
        .loading
    }

    func getMembersOfConversation(for courseId: Int, conversationId: Int64, page: Int) async -> DataState<[ConversationUser]> {
        .loading
    }

    func archiveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        .loading
    }

    func unarchiveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        .loading
    }

    func uploadFile(for courseId: Int, and conversationId: Int64, file: Data, filename: String, mimeType: String) async -> DataState<String> {
        .loading
    }

    func getUnresolvedChannelIds(for courseId: Int, and channelIds: [Int64]) async -> DataState<[Int64]> {
        .loading
    }

    func deleteChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        .loading
    }

    func getSavedPosts(for courseId: Int, status: SavedPostStatus) async -> DataState<[SavedPostDTO]> {
        .loading
    }

    func updateSavedPostStatus(for postId: Int, with type: PostType, status: SavedPostStatus) async -> NetworkResponse {
        .loading
    }

    func deleteSavedPost(with postId: Int, of type: PostType) async -> NetworkResponse {
        .loading
    }

    func addSavedPost(with postId: Int, of type: PostType) async -> NetworkResponse {
        .loading
    }
}
