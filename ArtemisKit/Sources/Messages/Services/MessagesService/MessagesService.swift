//
//  MessagesService.swift
//  
//
//  Created by Sven Andabaka on 03.04.23.
//

import Foundation
import Common
import APIClient
import SharedModels
import UserStore

protocol MessagesService {

    /**
     * Perform a get request for all Conversations of a course to the server.
     */
    func getConversations(for courseId: Int) async -> DataState<[Conversation]>

    /**
     * Perform a hide/show post request for a specific Conversations of a specific course to the server.
     */
    func hideUnhideConversation(for courseId: Int, and conversationId: Int64, isHidden: Bool) async -> NetworkResponse

    /**
     * Perform a set favorite post request for a specific Conversations of a specific course to the server.
     */
    func setIsFavoriteConversation(for courseId: Int, and conversationId: Int64, isFavorite: Bool) async -> NetworkResponse

    /**
     Perform a set muted post request for a course's conversation to the server.
     */
    func setMutedConversation(for courseId: Int, and conversationId: Int64, muted: Muted) async -> NetworkResponse

    /**
     * Perform a get request for Messages of a specific conversation in a specific course to the server.
     */
    func getMessages(for courseId: Int, and conversationId: Int64, size: Int) async -> DataState<[Message]>

    /**
     * Perform a post request for a new message for a specific conversation in a specific course to the server.
     */
    func sendMessage(for courseId: Int, conversation: Conversation, content: String) async -> NetworkResponse

    /**
     * Perform a post request for a new message answer for a specific message in a specific course to the server.
     */
    func sendAnswerMessage(for courseId: Int, message: Message, content: String) async -> NetworkResponse

    /**
     * Perform a delete request for a message in a specific course to the server.
     */
    func deleteMessage(for courseId: Int, messageId: Int64) async -> NetworkResponse

    /**
     * Perform a delete request for a message answer in a specific course to the server.
     */
    func deleteAnswerMessage(for courseId: Int, anserMessageId: Int64) async -> NetworkResponse

    /**
     * Perform a put request to update a message in a specific course to the server.
     */
    func editMessage(for courseId: Int, message: Message) async -> NetworkResponse

    /**
     * Perform a put request to update a message answer in a specific course to the server.
     */
    func editAnswerMessage(for courseId: Int, answerMessage: AnswerMessage) async -> NetworkResponse

    /**
     * Perform a post request for a new reaction on an answer for a specific message in a specific course to the server.
     */
    func addReactionToAnswerMessage(for courseId: Int, answerMessage: AnswerMessage, emojiId: String) async -> NetworkResponse

    /**
     * Perform a post request for a new reaction for a specific message in a specific course to the server.
     */
    func addReactionToMessage(for courseId: Int, message: Message, emojiId: String) async -> NetworkResponse

    /**
     * Perform a delete request to remove a reaction from a specific message in a specific course to the server.
     */
    func removeReactionFromMessage(for courseId: Int, reaction: Reaction) async -> NetworkResponse

    /**
     * Perform a get request to retrieve all channels in a specific course to the server.
     */
    func getChannelsOverview(for courseId: Int) async -> DataState<[Channel]>

    /**
     * Perform a post request to add members to a specific channels in a specific course to the server.
     */
    func addMembersToChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> NetworkResponse

    /**
     * Perform a post request to remove members from a specific channels in a specific course to the server.
     */
    func removeMembersFromChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> NetworkResponse

    /**
     * Perform a post request to add members to a specific group chat in a specific course to the server.
     */
    func addMembersToGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> NetworkResponse

    /**
     * Perform a post request to remove members from a specific group chat in a specific course to the server.
     */
    func removeMembersFromGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> NetworkResponse

    /**
     * Perform a post request to create a specific channels in a specific course to the server.
     */
    func createChannel(for courseId: Int, name: String, description: String?, isPrivate: Bool, isAnnouncement: Bool) async -> DataState<Channel>

    /**
     * Perform a get request to find users in a specific course to the server.
     */
    func searchForUsers(for courseId: Int, searchText: String) async -> DataState<[ConversationUser]>

    /**
     * Perform a post request to create a specific group chat in a specific course to the server.
     */
    func createGroupChat(for courseId: Int, usernames: [String]) async -> DataState<GroupChat>

    /**
     * Perform a post request to create a specific oneToOne chat in a specific course to the server.
     */
    func createOneToOneChat(for courseId: Int, usernames: [String]) async -> DataState<OneToOneChat>

    /**
     * Perform a get request to find 20 users with paging of a specific conversation in a specific course to the server.
     */
    func getMembersOfConversation(for courseId: Int, conversationId: Int64, page: Int) async -> DataState<[ConversationUser]>

    /**
     * Perform a post request to archive  a specific channel in a specific course to the server.
     */
    func archiveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse

    /**
     * Perform a post request to unarchive  a specific channel in a specific course to the server.
     */
    func unarchiveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse

    /**
     * Perform a put request to edit the name/topic/description of  a specific conversation in a specific course to the server.
     */
    func editConversation(for courseId: Int, conversation: Conversation, newName: String?, newTopic: String?, newDescription: String?) async -> DataState<Conversation>
}

extension MessagesService {
    func joinChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        guard let username = UserSession.shared.user?.login else { return .failure(error: UserFacingError(error: APIClientError.wrongParameters)) }

        return await addMembersToChannel(for: courseId, channelId: channelId, usernames: [username])
    }

    func leaveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        guard let username = UserSession.shared.user?.login else { return .failure(error: UserFacingError(error: APIClientError.wrongParameters)) }

        return await removeMembersFromChannel(for: courseId, channelId: channelId, usernames: [username])
    }

    func leaveConversation(for courseId: Int, groupChatId: Int64) async -> NetworkResponse {
        guard let username = UserSession.shared.user?.login else { return .failure(error: UserFacingError(error: APIClientError.wrongParameters)) }

        return await removeMembersFromGroupChat(for: courseId, groupChatId: groupChatId, usernames: [username])
    }

    func editConversation(for courseId: Int, conversation: Conversation, newName: String? = nil, newTopic: String? = nil, newDescription: String? = nil) async -> DataState<Conversation> {
        return await editConversation(for: courseId, conversation: conversation, newName: newName, newTopic: newTopic, newDescription: newDescription)
    }
}

enum MessagesServiceFactory {
    static let shared: MessagesService = MessagesServiceImpl()
}
