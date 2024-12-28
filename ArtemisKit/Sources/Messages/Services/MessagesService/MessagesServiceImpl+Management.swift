//
//  File.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 28.12.24.
//

import APIClient
import Common
import Foundation
import SharedModels

// Requests for Conversation Management
extension MessagesServiceImpl {
    struct GetUnresolvedChannelsRequest: APIRequest {
        typealias Response = [UnresolvedChannelsResponse]
        struct UnresolvedChannelsResponse: Codable {
            let conversation: Conversation
        }

        let courseId: Int
        let channelIds: [Int64]
        var channelIdsString: String {
            channelIds.map(String.init(describing:)).joined(separator: ",")
        }

        var method: HTTPMethod {
            return .get
        }

        var params: [URLQueryItem] {
            [
                .init(name: "courseWideChannelIds", value: channelIdsString),
                .init(name: "postSortCriterion", value: "CREATION_DATE"),
                .init(name: "sortingOrder", value: "DESCENDING"),
                .init(name: "pagingEnabled", value: "true"),
                .init(name: "page", value: "0"),
                .init(name: "size", value: "\(50)")
            ] + MessageRequestFilter(filterToUnresolved: true).queryItems
        }

        var resourceName: String {
            return "api/courses/\(courseId)/messages"
        }
    }

    func getUnresolvedChannelIds(for courseId: Int, and channelIds: [Int64]) async -> DataState<[Int64]> {
        let result = await client.sendRequest(GetUnresolvedChannelsRequest(courseId: courseId, channelIds: channelIds))

        switch result {
        case let .success((conversations, _)):
            let ids = conversations.map(\.conversation.id)
            return .done(response: Array(Set(ids)))
        case let .failure(error):
            return DataState(error: error)
        }
    }
}
