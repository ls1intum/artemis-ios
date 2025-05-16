//
//  MessagesService+Forward.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 16.05.25.
//

import APIClient
import Common
import Foundation
import SharedModels

// The API for forwarded messages is super horrible, so we contain the logic for that here

extension MessagesServiceImpl {
    struct GetForwardedMessageIdsRequest: APIRequest {
        typealias Response = [ForwardedMessagesGroupDTO]

        var method: HTTPMethod { .get }

        let ids: [Int64]

        var resourceName: String {
            "api/communication/forwarded-messages"
        }

        var params: [URLQueryItem] {
            [
                .init(name: "postingIds", value: ids.map(String.init).joined(separator: ",")),
                .init(name: "type", value: "POST")
            ]
        }
    }

    func getForwardedMessages(for postIds: [Int64], courseId: Int) async -> DataState<[ForwardedMessagesGroupDTO]> {
        var messageGroups: [ForwardedMessagesGroupDTO] = []

        // Fetch ids for source posts
        let response = await client.sendRequest(GetForwardedMessageIdsRequest(ids: postIds))
        switch response {
        case .failure(let error):
            return .failure(error: .init(error: error))
        case .success(let (groups, _)):
            messageGroups = groups
        }

        let postGroups = messageGroups.filter { $0.sourceMessageType == .post }
        let answerGroups = messageGroups.filter { $0.sourceMessageType == .answer }

        // Fetch source posts/answers
        async let sourcePosts = await loadForwardedPosts(with: postGroups.compactMap(\.sourceMessageId), courseId: courseId)
        async let sourceAnswers = await loadForwardedAnswers(with: answerGroups.compactMap(\.sourceMessageId), courseId: courseId)

        // Store them all in a list
        var allSources: [any BaseMessage] = []
        switch await sourcePosts {
        case .done(let response): allSources += response
        default: break
        }
        switch await sourceAnswers {
        case .done(let response): allSources += response
        default: break
        }

        messageGroups = messageGroups.map { group in
            let message = allSources.first { $0.id == group.sourceMessageId }
            return ForwardedMessagesGroupDTO(id: group.id, messages: [], sourceMessage: message)
        }

        return .done(response: messageGroups)
    }

    private struct GetSourcePostsRequest: APIRequest {
        typealias Response = [Message]
        var method: HTTPMethod { .get }

        let courseId: Int
        let postIds: [Int64]

        var resourceName: String {
            "api/communication/courses/\(courseId)/messages-source-posts"
        }

        var params: [URLQueryItem] {
            [.init(name: "postIds", value: postIds.map(String.init).joined(separator: ","))]
        }
    }

    private func loadForwardedPosts(with ids: [Int64], courseId: Int) async -> DataState<[Message]> {
        let response = await client.sendRequest(GetSourcePostsRequest(courseId: courseId, postIds: ids))
        switch response {
        case .success(let (data, _)):
            return .done(response: data)
        case .failure(let error):
            return .failure(error: .init(error: error))
        }
    }

    private struct GetSourceAnswersRequest: APIRequest {
        typealias Response = [AnswerMessage]
        var method: HTTPMethod { .get }

        let courseId: Int
        let postIds: [Int64]

        var resourceName: String {
            "api/communication/courses/\(courseId)/answer-messages-source-posts"
        }

        var params: [URLQueryItem] {
            [.init(name: "answerPostIds", value: postIds.map(String.init).joined(separator: ","))]
        }
    }

    private func loadForwardedAnswers(with ids: [Int64], courseId: Int) async -> DataState<[AnswerMessage]> {
        let response = await client.sendRequest(GetSourceAnswersRequest(courseId: courseId, postIds: ids))
        switch response {
        case .success(let (data, _)):
            return .done(response: data)
        case .failure(let error):
            return .failure(error: .init(error: error))
        }
    }
}
