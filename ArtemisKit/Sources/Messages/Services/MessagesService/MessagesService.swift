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
     * Perform a get request for all conversations of a course to the server.
     */
    func getConversations(for courseId: Int) async -> DataState<[Conversation]>

    /**
     * Perform an update favorite post request for a specific conversation of a specific course to the server.
     */
    func updateIsConversationFavorite(for courseId: Int, and conversationId: Int64, isFavorite: Bool) async -> NetworkResponse

    /**
     * Perform an update muted post request for a specific conversation of a specific course to the server.
     */
    func updateIsConversationMuted(for courseId: Int, and conversationId: Int64, isMuted: Bool) async -> NetworkResponse

    /**
     * Perform an update hide/show post request for a specific conversation of a specific course to the server.
     */
    func updateIsConversationHidden(for courseId: Int, and conversationId: Int64, isHidden: Bool) async -> NetworkResponse

    /**
     * Perform a get request for Messages of a specific conversation in a specific course to the server.
     */
    func getMessages(for courseId: Int, and conversationId: Int64, filter: MessageRequestFilter, page: Int) async -> DataState<[Message]>

    /**
     * Perform a get request for a specific Message of a specific conversation in a specific course to the server.
     */
    func getMessage(with messageId: Int64, for courseId: Int, and conversationId: Int64) async -> DataState<Message>

    /**
     * Perform a post request for a new message for a specific conversation in a specific course to the server.
     */
    func sendMessage(for courseId: Int, conversation: Conversation, content: String) async -> NetworkResponse

    /**
     * Perform a post request for a new message answer for a specific message in a specific course to the server.
     */
    func sendAnswerMessage(for courseId: Int, message: Message, content: String) async -> NetworkResponse

    /**
     * Perform a post request for uploading a file  in a specific conversation to the server.
     */
    func uploadFile(for courseId: Int, and conversationId: Int64, file: Data, filename: String, mimeType: String) async -> DataState<String>

    /**
     * Perform a delete request for a message in a specific course to the server.
     */
    func deleteMessage(for courseId: Int, messageId: Int64) async -> NetworkResponse

    /**
     * Perform a delete request for a message answer in a specific course to the server.
     */
    func deleteAnswerMessage(for courseId: Int, anserMessageId: Int64) async -> NetworkResponse

    /**
     * Perform a put request to update a message's display priority in a specific course to the server.
     */
    func updateMessageDisplayPriority(for courseId: Int64, messageId: Int64, displayPriority: DisplayPriority) async -> DataState<any BaseMessage>

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
     * Perform a get request to retrieve all channels in the public overview in a specific course to the server.
     */
    func getChannelsPublicOverview(for courseId: Int) async -> DataState<[ChannelIdAndNameDTO]>

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
    func createChannel(for courseId: Int, name: String, description: String?, isPrivate: Bool, isAnnouncement: Bool, isCourseWide: Bool) async -> DataState<Channel>

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

    /**
     * Perform a get request to retrieve channels which have unresolved messages
     */
    func getUnresolvedChannelIds(for courseId: Int, and channelIds: [Int64]) async -> DataState<[Int64]>

    /**
     * Perform a delete request to delete a specific channel in a specific course to the server.
     */
    func deleteChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse

    // MARK: Saved Messages
    /**
     * Perform a post request to add the specified post to the list of saved posts..
     */
    func addSavedPost(with postId: Int, of type: PostType) async -> NetworkResponse

    /**
     * Perform a get request to find all saved posts in a course that have the given status.
     */
    func getSavedPosts(for courseId: Int, status: SavedPostStatus) async -> DataState<[SavedPostDTO]>

    /**
     * Perform a put request to update a saved post's status.
     */
    func updateSavedPostStatus(for postId: Int, with type: PostType, status: SavedPostStatus) async -> NetworkResponse

    /**
     * Perform a delete request to remove the saved post with given id from the list of saved posts..
     */
    func deleteSavedPost(with postId: Int, of type: PostType) async -> NetworkResponse
}

extension MessagesService {
    func joinChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        guard let username = UserSessionFactory.shared.user?.login else { return .failure(error: UserFacingError(error: APIClientError.wrongParameters)) }

        return await addMembersToChannel(for: courseId, channelId: channelId, usernames: [username])
    }

    func leaveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        guard let username = UserSessionFactory.shared.user?.login else { return .failure(error: UserFacingError(error: APIClientError.wrongParameters)) }

        return await removeMembersFromChannel(for: courseId, channelId: channelId, usernames: [username])
    }

    func leaveConversation(for courseId: Int, groupChatId: Int64) async -> NetworkResponse {
        guard let username = UserSessionFactory.shared.user?.login else { return .failure(error: UserFacingError(error: APIClientError.wrongParameters)) }

        return await removeMembersFromGroupChat(for: courseId, groupChatId: groupChatId, usernames: [username])
    }

    func editConversation(for courseId: Int, conversation: Conversation, newName: String? = nil, newTopic: String? = nil, newDescription: String? = nil) async -> DataState<Conversation> {
        return await editConversation(for: courseId, conversation: conversation, newName: newName, newTopic: newTopic, newDescription: newDescription)
    }
}

enum MessagesServiceFactory: DependencyFactory {
    static let liveValue: MessagesService = MessagesServiceImpl()

    static let testValue: MessagesService = MessagesServiceStub()
}
