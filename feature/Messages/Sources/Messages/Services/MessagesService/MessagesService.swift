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
     * Perform a get request for Messages to the server.
     */
    func getConversations(for courseId: Int) async -> DataState<[Conversation]>
}

enum MessagesServiceFactory {
    static let shared: MessagesService = MessagesServiceImpl()
}
