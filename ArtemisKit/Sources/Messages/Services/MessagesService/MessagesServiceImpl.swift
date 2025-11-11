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
struct MessagesServiceImpl: MessagesService {

    internal let client = APIClient()

    struct GetConversationsRequest: APIRequest {
        typealias Response = [Conversation]

        let courseId: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/conversations"
        }
    }

    func getConversations(for courseId: Int) async -> DataState<[Conversation]> {
        let result = await client.sendRequest(GetConversationsRequest(courseId: courseId))

        switch result {
        case let .success((conversations, _)):
            return .done(response: conversations)
        case let .failure(error):
            return DataState(error: error)
        }
    }

    struct UpdateIsConversationFavoriteRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let conversationId: Int64
        let isFavorite: Bool

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/conversations/\(conversationId)/favorite?isFavorite=\(isFavorite)"
        }
    }

    func updateIsConversationFavorite(for courseId: Int, and conversationId: Int64, isFavorite: Bool) async -> NetworkResponse {
        let result = await client.sendRequest(
            UpdateIsConversationFavoriteRequest(courseId: courseId, conversationId: conversationId, isFavorite: isFavorite)
        )

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    struct UpdateIsConversationMutedRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let conversationId: Int64
        let isMuted: Bool

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/conversations/\(conversationId)/muted?isMuted=\(isMuted)"
        }
    }

    func updateIsConversationMuted(for courseId: Int, and conversationId: Int64, isMuted: Bool) async -> NetworkResponse {
        let result = await client.sendRequest(
            UpdateIsConversationMutedRequest(courseId: courseId, conversationId: conversationId, isMuted: isMuted)
        )

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    struct UpdateIsConversationHiddenRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let conversationId: Int64
        let isHidden: Bool

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/conversations/\(conversationId)/hidden?isHidden=\(isHidden)"
        }
    }

    func updateIsConversationHidden(for courseId: Int, and conversationId: Int64, isHidden: Bool) async -> NetworkResponse {
        let result = await client.sendRequest(
            UpdateIsConversationHiddenRequest(courseId: courseId, conversationId: conversationId, isHidden: isHidden)
        )

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    struct GetMessagesRequest: APIRequest {
        typealias Response = [Message]

        static let size = 50

        let courseId: Int
        let conversationId: Int64
        let page: Int
        let filter: MessageRequestFilter

        var method: HTTPMethod {
            return .get
        }

        var params: [URLQueryItem] {
            [
                .init(name: "conversationIds", value: "\(conversationId)"),
                .init(name: "postSortCriterion", value: "CREATION_DATE"),
                .init(name: "sortingOrder", value: "DESCENDING"),
                .init(name: "pagingEnabled", value: "true"),
                .init(name: "page", value: String(describing: page)),
                .init(name: "size", value: String(describing: Self.size))
            ] + filter.queryItems
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/messages"
        }
    }

    func getMessages(for courseId: Int, and conversationId: Int64, filter: MessageRequestFilter = .init(), page: Int) async -> DataState<[Message]> {
        let result = await client.sendRequest(GetMessagesRequest(courseId: courseId, conversationId: conversationId, page: page, filter: filter))

        switch result {
        case let .success((messages, _)):
            return .done(response: messages)
        case let .failure(error):
            return DataState(error: error)
        }
    }

    struct SearchMessagesRequest: APIRequest {
        typealias Response = [Message]

        let courseId: Int
        let channelIds: [Int64]
        let searchTerm: String
        var channelIdsString: String {
            channelIds.map(String.init(describing:)).joined(separator: ",")
        }

        var method: HTTPMethod {
            return .get
        }

        var params: [URLQueryItem] {
            [
                .init(name: "conversationIds", value: channelIdsString),
                .init(name: "postSortCriterion", value: "CREATION_DATE"),
                .init(name: "sortingOrder", value: "DESCENDING"),
                .init(name: "searchText", value: searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""),
                .init(name: "pagingEnabled", value: "true"),
                .init(name: "page", value: "0"),
                .init(name: "size", value: "20")
            ]
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/messages"
        }
    }

    func searchMessages(for courseId: Int, channelIds: [Int64], searchTerm: String) async -> DataState<[Message]> {
        let result = await client.sendRequest(SearchMessagesRequest(courseId: courseId, channelIds: channelIds, searchTerm: searchTerm))

        switch result {
        case let .success((messages, _)):
            return .done(response: messages)
        case let .failure(error):
            return DataState(error: error)
        }
    }

    struct GetMessageRequest: APIRequest {
        typealias Response = [Message]

        let courseId: Int
        let conversationId: Int64
        let messageId: Int64

        var method: HTTPMethod {
            return .get
        }

        var params: [URLQueryItem] {
            [
                .init(name: "conversationIds", value: String(describing: conversationId)),
                .init(name: "searchText", value: "#\(messageId)")
            ]
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/messages"
        }
    }

    func getMessage(with messageId: Int64, for courseId: Int, and conversationId: Int64) async -> DataState<Message> {
        let result = await client.sendRequest(GetMessageRequest(courseId: courseId, conversationId: conversationId, messageId: messageId))

        switch result {
        case let .success((messages, _)):
            if let message = messages.first {
                return .done(response: message)
            } else {
                return .failure(error: .init(title: "Message not found"))
            }
        case let .failure(error):
            return DataState(error: error)
        }
    }

    struct SendMessageRequest: APIRequest {
        typealias Response = Message

        let courseId: Int
        let visibleForStudents: Bool
        let displayPriority: DisplayPriority
        let conversation: Conversation
        let content: String
        let hasForwardedMessages: Bool?

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/messages"
        }
    }

    func sendMessage(for courseId: Int, conversation: Conversation, content: String, hasForwardedMessages: Bool? = nil) async -> DataState<Message> {
        let result = await client.sendRequest(
            SendMessageRequest(courseId: courseId, visibleForStudents: true, displayPriority: .noInformation, conversation: conversation, content: content, hasForwardedMessages: hasForwardedMessages)
        )

        switch result {
        case .success(let response):
            NotificationCenter.default.post(name: .newMessageSent,
                                            object: nil,
                                            userInfo: ["message": response.0])
            return .done(response: response.0)
        case let .failure(error):
            return .failure(error: .init(error: error))
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
            return "api/communication/courses/\(courseId)/answer-messages"
        }
    }

    func sendAnswerMessage(for courseId: Int, message: Message, content: String) async -> NetworkResponse {
        let result = await client.sendRequest(
            SendAnswerMessageRequest(resolvesPost: false, content: content, post: message, courseId: courseId)
        )

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    struct UploadFileResult: Codable {
        let path: String
    }

       func uploadFile(for courseId: Int, and conversationId: Int64, file: Data, filename: String, mimeType: String) async -> DataState<String> {
           // Check file size limit
           let maxFileSize = 5 * 1024 * 1024
           if file.count > maxFileSize {
               return .failure(error: .init(title: "File too big to upload"))
           }

           let request = MultipartFormDataRequest(path: "api/core/files/courses/\(courseId)/conversations/\(conversationId)")
           request.addDataField(named: "file",
                                filename: filename,
                                data: file,
                                mimeType: mimeType)

           let result: Swift.Result<(UploadFileResult, Int), APIClientError> = await client.sendRequest(request)

           switch result {
           case .success(let response):
               return .done(response: response.0.path)
           case .failure(let failure):
               return .failure(error: .init(error: failure))
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
            return "api/communication/courses/\(courseId)/messages/\(messageId)"
        }
    }

    func deleteMessage(for courseId: Int, messageId: Int64) async -> NetworkResponse {
        let result = await client.sendRequest(DeleteMessageRequest(messageId: messageId, courseId: courseId))

        switch result {
        case .success:
            return .success
        case let .failure(error):
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
            return "api/communication/courses/\(courseId)/answer-messages/\(messageId)"
        }
    }

    func deleteAnswerMessage(for courseId: Int, anserMessageId: Int64) async -> NetworkResponse {
        let result = await client.sendRequest(DeleteAnswerMessageRequest(messageId: anserMessageId, courseId: courseId))

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    struct EditMessageRequest: APIRequest {
        typealias Response = RawResponse

        let message: Message
        let courseId: Int

        var method: HTTPMethod {
            return .put
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/messages/\(message.id)"
        }

        func encode(to encoder: Encoder) throws {
            try message.encode(to: encoder)
        }
    }

    func editMessage(for courseId: Int, message: Message) async -> NetworkResponse {
        let result = await client.sendRequest(EditMessageRequest(message: message, courseId: courseId))

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    struct UpdateDisplayPriorityRequest: APIRequest {
        typealias Response = Message

        let courseId: Int64
        let messageId: Int64
        let displayPriority: DisplayPriority

        var method: HTTPMethod {
            return .put
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/messages/\(messageId)/display-priority"
        }

        var params: [URLQueryItem] {
            [.init(name: "displayPriority", value: displayPriority.rawValue)]
        }
    }

    func updateMessageDisplayPriority(for courseId: Int64, messageId: Int64, displayPriority: DisplayPriority) async -> DataState<any BaseMessage> {
        let result = await client.sendRequest(UpdateDisplayPriorityRequest(courseId: courseId, messageId: messageId, displayPriority: displayPriority))

        switch result {
        case .success((let message, _)):
            return .done(response: message)
        case let .failure(error):
            return .failure(error: .init(error: error))
        }
    }

    struct EditAnswerMessageRequest: APIRequest {
        typealias Response = RawResponse

        let answerMessage: AnswerMessage
        let courseId: Int

        var method: HTTPMethod {
            return .put
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/answer-messages/\(answerMessage.id)"
        }

        func encode(to encoder: Encoder) throws {
            try answerMessage.encode(to: encoder)
        }
    }

    func editAnswerMessage(for courseId: Int, answerMessage: AnswerMessage) async -> NetworkResponse {
        let result = await client.sendRequest(EditAnswerMessageRequest(answerMessage: answerMessage, courseId: courseId))

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    func addReactionToAnswerMessage(for courseId: Int, answerMessage: AnswerMessage, emojiId: String) async -> NetworkResponse {
        let result = await client.sendRequest(
            AddReactionToMessageRequest(emojiId: emojiId, relatedPostId: answerMessage.id, courseId: courseId)
        )

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    struct AddReactionToMessageRequest: APIRequest {
        typealias Response = RawResponse

        let emojiId: String
        let relatedPostId: Int64
        let courseId: Int

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/postings/reactions"
        }
    }

    func addReactionToMessage(for courseId: Int, message: Message, emojiId: String) async -> NetworkResponse {
        let result = await client.sendRequest(
            AddReactionToMessageRequest(emojiId: emojiId, relatedPostId: message.id, courseId: courseId)
        )

        switch result {
        case .success:
            return .success
        case let .failure(error):
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
            return "api/communication/courses/\(courseId)/postings/reactions/\(reactionId)"
        }
    }

    func removeReactionFromMessage(for courseId: Int, reaction: Reaction) async -> NetworkResponse {
        let result = await client.sendRequest(RemoveReactionFromMessageRequest(courseId: courseId, reactionId: reaction.id))

        switch result {
        case .success:
            return .success
        case let .failure(error):
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
            return "api/communication/courses/\(courseId)/channels/overview"
        }
    }

    func getChannelsOverview(for courseId: Int) async -> DataState<[Channel]> {
        let result = await client.sendRequest(GetChannelsOverviewRequest(courseId: courseId))

        switch result {
        case let .success((channels, _)):
            return .done(response: channels)
        case let .failure(error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct GetChannelsPublicOverviewRequest: APIRequest {
        typealias Response = [ChannelIdAndNameDTO]

        let courseId: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/channels/public-overview"
        }
    }

    func getChannelsPublicOverview(for courseId: Int) async -> DataState<[ChannelIdAndNameDTO]> {
        let result = await client.sendRequest(GetChannelsPublicOverviewRequest(courseId: courseId))

        switch result {
        case let .success((channels, _)):
            return .done(response: channels)
        case let .failure(error):
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
            return "api/communication/courses/\(courseId)/channels/\(channelId)/register"
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
        case let .failure(error):
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
            return "api/communication/courses/\(courseId)/channels/\(channelId)/deregister"
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
        case let .failure(error):
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
            return "api/communication/courses/\(courseId)/group-chats/\(groupChatId)/register"
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
        case let .failure(error):
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
            return "api/communication/courses/\(courseId)/group-chats/\(groupChatId)/deregister"
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
        case let .failure(error):
            return .failure(error: error)
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
            return "api/core/courses/\(courseId)/users/search?loginOrName=\(searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&roles=students,tutors,instructors"
        }
    }

    func searchForUsers(for courseId: Int, searchText: String) async -> DataState<[ConversationUser]> {
        let result = await client.sendRequest(SearchForUsersRequest(courseId: courseId, searchText: searchText))

        switch result {
        case let .success((users, _)):
            return .done(response: users)
        case let .failure(error):
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
            return "api/communication/courses/\(courseId)/group-chats"
        }

        func encode(to encoder: Encoder) throws {
            try usernames.encode(to: encoder)
        }
    }

    func createGroupChat(for courseId: Int, usernames: [String]) async -> DataState<GroupChat> {
        let result = await client.sendRequest(CreateGroupChatRequest(courseId: courseId, usernames: usernames))

        switch result {
        case let .success((groupChat, _)):
            return .done(response: groupChat)
        case let .failure(error):
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
            return "api/communication/courses/\(courseId)/one-to-one-chats"
        }

        func encode(to encoder: Encoder) throws {
            try usernames.encode(to: encoder)
        }
    }

    func createOneToOneChat(for courseId: Int, usernames: [String]) async -> DataState<OneToOneChat> {
        let result = await client.sendRequest(CreateOneToOneChatRequest(courseId: courseId, usernames: usernames))

        switch result {
        case let .success((oneToOneChat, _)):
            return .done(response: oneToOneChat)
        case let .failure(error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct CreateOneToOneChatByIdRequest: APIRequest {
        typealias Response = OneToOneChat

        let courseId: Int
        let userId: Int

        var method: HTTPMethod {
            .post
        }

        var resourceName: String {
            "api/communication/courses/\(courseId)/one-to-one-chats/\(userId)"
        }
    }

    func createOneToOneChat(for courseId: Int, userId: Int) async -> DataState<OneToOneChat> {
        let result = await client.sendRequest(CreateOneToOneChatByIdRequest(courseId: courseId, userId: userId))

        switch result {
        case let .success((oneToOneChat, _)):
            return .done(response: oneToOneChat)
        case let .failure(error):
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

        var params: [URLQueryItem] {
            [
                .init(name: "loginOrName", value: searchText ?? ""),
                .init(name: "sort", value: "firstName,asc"),
                .init(name: "sort", value: "lastName,asc"),
                .init(name: "page", value: String(describing: page)),
                .init(name: "size", value: "20")
            ]
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/conversations/\(conversationId)/members/search"
        }
    }

    func getMembersOfConversation(for courseId: Int, conversationId: Int64, page: Int) async -> DataState<[ConversationUser]> {
        let result = await client.sendRequest(
            GetMembersOfConversationRequest(courseId: courseId, conversationId: conversationId, searchText: nil, page: page)
        )

        switch result {
        case let .success((users, _)):
            return .done(response: users)
        case let .failure(error):
            return .failure(error: UserFacingError(error: error))
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
            return "api/communication/courses/\(courseId)/\(typePath)/\(conversationId)"
        }
    }

    func editConversation(for courseId: Int, conversation: Conversation, newName: String?, newTopic: String?, newDescription: String?) async -> DataState<Conversation> {
        guard let typePath = conversation.baseConversation.type.path else {
            return .failure(error: UserFacingError(title: R.string.localizable.unsupportedConversationType()))
        }

        let result = await client.sendRequest(
            RenameConversationRequest(
                courseId: courseId,
                conversationId: conversation.id,
                type: conversation.baseConversation.type,
                typePath: typePath,
                name: newName,
                topic: newTopic,
                description: newDescription)
        )

        switch result {
        case let .success((conversation, _)):
            return .done(response: conversation)
        case let .failure(error):
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

// MARK: Reload Notification

extension Foundation.Notification.Name {
    // Sending a notification of this type causes the Conversation
    // to add the newly sent message in case the web socket fails
    static let newMessageSent = Foundation.Notification.Name("NewMessageSent")
}
