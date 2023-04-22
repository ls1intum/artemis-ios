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

    struct JoinChannelRequest: APIRequest {
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

    func joinChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        guard let username = UserSession.shared.user?.login else { return .failure(error: APIClientError.wrongParameters) }

        let result = await client.sendRequest(JoinChannelRequest(channelId: channelId, courseId: courseId, usernames: [username]))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }
}
