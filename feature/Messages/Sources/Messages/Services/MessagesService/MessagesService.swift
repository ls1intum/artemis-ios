//
//  MessagesService.swift
//  
//
//  Created by Sven Andabaka on 03.04.23.
//

import Foundation
import Common
import SharedModels

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
}

enum MessagesServiceFactory {
    static let shared: MessagesService = MessagesServiceImpl()
}
