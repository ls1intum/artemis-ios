//
//  File.swift
//  
//
//  Created by Sven Andabaka on 03.04.23.
//

import Foundation
import APIClient
import Common
import SharedModels
import UserStore

// swiftlint:disable file_length type_body_length
class MessagesServiceImpl: MessagesService {

    private let client = APIClient()

    struct GetConversationsRequest: APIRequest {
        typealias Response = [Conversation]

        let courseId: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/courses/\(courseId)/conversations"
        }
    }

    func getConversations(for courseId: Int) async -> DataState<[Conversation]> {
        let result = await client.sendRequest(GetConversationsRequest(courseId: courseId))

        switch result {
        case .success((let conversations, _)):
            return .done(response: conversations)
        case .failure(let error):
            return DataState(error: error)
        }
    }

    struct HideUnhideConversationRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let conversationId: Int64
        let isHidden: Bool

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/conversations/\(conversationId)/hidden?isHidden=\(isHidden)"
        }
    }

    func hideUnhideConversation(for courseId: Int, and conversationId: Int64, isHidden: Bool) async -> NetworkResponse {
        let result = await client.sendRequest(HideUnhideConversationRequest(courseId: courseId,
                                                                            conversationId: conversationId,
                                                                            isHidden: isHidden))
        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct SetIsFavoriteConversationRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let conversationId: Int64
        let isFavorite: Bool

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/conversations/\(conversationId)/favorite?isFavorite=\(isFavorite)"
        }
    }

    func setIsFavoriteConversation(for courseId: Int, and conversationId: Int64, isFavorite: Bool) async -> NetworkResponse {
        let result = await client.sendRequest(SetIsFavoriteConversationRequest(courseId: courseId,
                                                                               conversationId: conversationId,
                                                                               isFavorite: isFavorite))
        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct GetMessagesRequest: APIRequest {
        typealias Response = [Message]

        let courseId: Int
        let conversationId: Int64
        let size: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/courses/\(courseId)/messages?postSortCriterion=CREATION_DATE&sortingOrder=ASCENDING&conversationId=\(conversationId)&pagingEnabled=true&page=0&size=\(size)"
        }
    }

    func getMessages(for courseId: Int, and conversationId: Int64, size: Int) async -> DataState<[Message]> {
        let result = await client.sendRequest(GetMessagesRequest(courseId: courseId, conversationId: conversationId, size: size))

        switch result {
        case .success((let messages, _)):
            return .done(response: messages)
        case .failure(let error):
            return DataState(error: error)
        }
    }

    struct SendMessageRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let visibleForStudents: Bool
        let displayPriority: DisplayPriority
        let conversation: Conversation
        let content: String

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/messages"
        }
    }

    func sendMessage(for courseId: Int, conversation: Conversation, content: String) async -> NetworkResponse {
        let result = await client.sendRequest(SendMessageRequest(courseId: courseId,
                                                                 visibleForStudents: true,
                                                                 displayPriority: .noInformation,
                                                                 conversation: conversation,
                                                                 content: content))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct SendAnswerMessageRequest: APIRequest {
        typealias Response = RawResponse

        let resolvesPost: Bool
        let content: String
        let post: Message
        let courseId: Int

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/answer-messages"
        }
    }

    func sendAnswerMessage(for courseId: Int, message: Message, content: String) async -> NetworkResponse {
        let result = await client.sendRequest(SendAnswerMessageRequest(resolvesPost: false,
                                                                       content: content,
                                                                       post: message,
                                                                       courseId: courseId))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct DeleteMessageRequest: APIRequest {
        typealias Response = RawResponse

        let messageId: Int64
        let courseId: Int

        var method: HTTPMethod {
            return .delete
        }

        var resourceName: String {
            return "api/courses/\(courseId)/messages/\(messageId)"
        }
    }

    func deleteMessage(for courseId: Int, messageId: Int64) async -> NetworkResponse {
        let result = await client.sendRequest(DeleteMessageRequest(messageId: messageId, courseId: courseId))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct DeleteAnswerMessageRequest: APIRequest {
        typealias Response = RawResponse

        let messageId: Int64
        let courseId: Int

        var method: HTTPMethod {
            return .delete
        }

        var resourceName: String {
            return "api/courses/\(courseId)/answer-messages/\(messageId)"
        }
    }

    func deleteAnswerMessage(for courseId: Int, anserMessageId: Int64) async -> NetworkResponse {
        let result = await client.sendRequest(DeleteAnswerMessageRequest(messageId: anserMessageId, courseId: courseId))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }


    struct AddReactionToAnswerMessageRequest: APIRequest {
        typealias Response = RawResponse

        let emojiId: String
        let answerPost: AnswerMessage
        let courseId: Int

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/postings/reactions"
        }
    }

    func addReactionToAnswerMessage(for courseId: Int, answerMessage: AnswerMessage, emojiId: String) async -> NetworkResponse {
        let result = await client.sendRequest(AddReactionToAnswerMessageRequest(emojiId: emojiId,
                                                                                answerPost: answerMessage,
                                                                                courseId: courseId))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct AddReactionToMessageRequest: APIRequest {
        typealias Response = RawResponse

        let emojiId: String
        let post: Message
        let courseId: Int

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/postings/reactions"
        }
    }

    func addReactionToMessage(for courseId: Int, message: Message, emojiId: String) async -> NetworkResponse {
        let result = await client.sendRequest(AddReactionToMessageRequest(emojiId: emojiId,
                                                                          post: message,
                                                                          courseId: courseId))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct RemoveReactionFromMessageRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let reactionId: Int64

        var method: HTTPMethod {
            return .delete
        }

        var resourceName: String {
            return "api/courses/\(courseId)/postings/reactions/\(reactionId)"
        }
    }

    func removeReactionFromMessage(for courseId: Int, reaction: Reaction) async -> NetworkResponse {
        let result = await client.sendRequest(RemoveReactionFromMessageRequest(courseId: courseId, reactionId: reaction.id))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct GetChannelsOverviewRequest: APIRequest {
        typealias Response = [Channel]

        let courseId: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/courses/\(courseId)/channels/overview"
        }
    }

    func getChannelsOverview(for courseId: Int) async -> DataState<[Channel]> {
        let result = await client.sendRequest(GetChannelsOverviewRequest(courseId: courseId))

        switch result {
        case .success((let channels, _)):
            return .done(response: channels)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct AddMembersToChannelRequest: APIRequest {
        typealias Response = RawResponse

        let channelId: Int64
        let courseId: Int
        let usernames: [String]

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/channels/\(channelId)/register"
        }

        func encode(to encoder: Encoder) throws {
            try usernames.encode(to: encoder)
        }
    }

    func addMembersToChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> NetworkResponse {
        let result = await client.sendRequest(AddMembersToChannelRequest(channelId: channelId, courseId: courseId, usernames: usernames))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct RemoveMembersFromChannelRequest: APIRequest {
        typealias Response = RawResponse

        let channelId: Int64
        let courseId: Int
        let usernames: [String]

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/channels/\(channelId)/deregister"
        }

        func encode(to encoder: Encoder) throws {
            try usernames.encode(to: encoder)
        }
    }

    func removeMembersFromChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> NetworkResponse {
        let result = await client.sendRequest(RemoveMembersFromChannelRequest(channelId: channelId, courseId: courseId, usernames: usernames))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct AddMembersToGroupChatRequest: APIRequest {
        typealias Response = RawResponse

        let groupChatId: Int64
        let courseId: Int
        let usernames: [String]

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/group-chats/\(groupChatId)/register"
        }

        func encode(to encoder: Encoder) throws {
            try usernames.encode(to: encoder)
        }
    }

    func addMembersToGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> NetworkResponse {
        let result = await client.sendRequest(AddMembersToGroupChatRequest(groupChatId: groupChatId, courseId: courseId, usernames: usernames))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct RemoveMembersFromGroupChatRequest: APIRequest {
        typealias Response = RawResponse

        let groupChatId: Int64
        let courseId: Int
        let usernames: [String]

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/group-chats/\(groupChatId)/deregister"
        }

        func encode(to encoder: Encoder) throws {
            try usernames.encode(to: encoder)
        }
    }

    func removeMembersFromGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> NetworkResponse {
        let result = await client.sendRequest(RemoveMembersFromGroupChatRequest(groupChatId: groupChatId, courseId: courseId, usernames: usernames))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct CreateChannelRequest: APIRequest {
        typealias Response = Channel

        let courseId: Int
        var type: ConversationType = .channel
        let name: String
        let description: String?
        let isPublic: Bool
        let isAnnouncementChannel: Bool

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/channels"
        }
    }

    func createChannel(for courseId: Int, name: String, description: String?, isPrivate: Bool, isAnnouncement: Bool) async -> DataState<Channel> {
        let result = await client.sendRequest(CreateChannelRequest(courseId: courseId,
                                                                   name: name,
                                                                   description: description,
                                                                   isPublic: !isPrivate,
                                                                   isAnnouncementChannel: isAnnouncement))

        switch result {
        case .success((let channel, _)):
            return .done(response: channel)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct SearchForUsersRequest: APIRequest {
        typealias Response = [ConversationUser]

        let courseId: Int
        let searchText: String

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/courses/\(courseId)/users/search?loginOrName=\(searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&roles=students,tutors,instructors"
        }
    }

    func searchForUsers(for courseId: Int, searchText: String) async -> DataState<[ConversationUser]> {
        let result = await client.sendRequest(SearchForUsersRequest(courseId: courseId, searchText: searchText))

        switch result {
        case .success((let users, _)):
            return .done(response: users)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct CreateGroupChatRequest: APIRequest {
        typealias Response = GroupChat

        let courseId: Int
        let usernames: [String]

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/group-chats"
        }

        func encode(to encoder: Encoder) throws {
            try usernames.encode(to: encoder)
        }
    }

    func createGroupChat(for courseId: Int, usernames: [String]) async -> DataState<GroupChat> {
        let result = await client.sendRequest(CreateGroupChatRequest(courseId: courseId, usernames: usernames))

        switch result {
        case .success((let groupChat, _)):
            return .done(response: groupChat)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct CreateOneToOneChatRequest: APIRequest {
        typealias Response = OneToOneChat

        let courseId: Int
        let usernames: [String]

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/one-to-one-chats"
        }

        func encode(to encoder: Encoder) throws {
            try usernames.encode(to: encoder)
        }
    }

    func createOneToOneChat(for courseId: Int, usernames: [String]) async -> DataState<OneToOneChat> {
        let result = await client.sendRequest(CreateOneToOneChatRequest(courseId: courseId, usernames: usernames))

        switch result {
        case .success((let oneToOneChat, _)):
            return .done(response: oneToOneChat)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct GetMembersOfConversationRequest: APIRequest {
        typealias Response = [ConversationUser]

        let courseId: Int
        let conversationId: Int64
        let searchText: String?
        let page: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/courses/\(courseId)/conversations/\(conversationId)/members/search?loginOrName=\(searchText ?? "")&sort=firstName,asc&sort=lastName,asc&page=\(page)&size=20"
        }
    }

    func getMembersOfConversation(for courseId: Int, conversationId: Int64, page: Int) async -> DataState<[ConversationUser]> {
        let result = await client.sendRequest(GetMembersOfConversationRequest(courseId: courseId,
                                                                              conversationId: conversationId,
                                                                              searchText: nil,
                                                                              page: page))

        switch result {
        case .success((let users, _)):
            return .done(response: users)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct ArchiveChannelRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let channelId: Int64

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/channels/\(channelId)/archive"
        }
    }

    func archiveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        let result = await client.sendRequest(ArchiveChannelRequest(courseId: courseId, channelId: channelId))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct UnarchiveChannelRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let channelId: Int64

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/channels/\(channelId)/unarchive"
        }
    }

    func unarchiveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        let result = await client.sendRequest(UnarchiveChannelRequest(courseId: courseId, channelId: channelId))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct RenameConversationRequest: APIRequest {
        typealias Response = Conversation

        let courseId: Int
        let conversationId: Int64

        let type: ConversationType
        let typePath: String
        let name: String?
        let topic: String?
        let description: String?

        var method: HTTPMethod {
            return .put
        }

        var resourceName: String {
            return "api/courses/\(courseId)/\(typePath)/\(conversationId)"
        }
    }

    func editConversation(for courseId: Int, conversation: Conversation, newName: String?, newTopic: String?, newDescription: String?) async -> DataState<Conversation> {
        guard let typePath = conversation.baseConversation.type.path else { return .failure(error: UserFacingError(title: R.string.localizable.unsupportedConversationType()))}

        let result = await client.sendRequest(RenameConversationRequest(courseId: courseId,
                                                                        conversationId: conversation.id,
                                                                        type: conversation.baseConversation.type,
                                                                        typePath: typePath,
                                                                        name: newName,
                                                                        topic: newTopic,
                                                                        description: newDescription))

        switch result {
        case .success((let conversation, _)):
            return .done(response: conversation)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}

private extension ConversationType {
    var path: String? {
        switch self {
        case .oneToOneChat:
            return "one-to-one-chats"
        case .groupChat:
            return "group-chats"
        case .channel:
            return "channels"
        case .unknown:
            return nil
        }
    }
}
