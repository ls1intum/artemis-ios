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
     * Perform a get request for Messages of a specific conversation in a specific course to the server.
     */
    func getMessages(for courseId: Int, and conversationId: Int64) async -> DataState<[Message]>
}

enum MessagesServiceFactory {
    static let shared: MessagesService = MessagesServiceImpl()
}
