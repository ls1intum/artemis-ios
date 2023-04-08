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

    struct GetMessagesRequest: APIRequest {
        typealias Response = [Message]

        let courseId: Int
        let conversationId: Int64

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/courses/\(courseId)/messages?postSortCriterion=CREATION_DATE&sortingOrder=ASCENDING&conversationId=\(conversationId)&pagingEnabled=true&page=0&size=50"
        }
    }

    func getMessages(for courseId: Int, and conversationId: Int64) async -> DataState<[Message]> {
        let result = await client.sendRequest(GetMessagesRequest(courseId: courseId, conversationId: conversationId))

        switch result {
        case .success((let messages, _)):
            return .done(response: messages)
        case .failure(let error):
            return DataState(error: error)
        }
    }
}