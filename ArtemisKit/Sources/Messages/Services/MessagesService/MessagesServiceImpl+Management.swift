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
    struct CreateChannelRequest: APIRequest {
        typealias Response = Channel

        let courseId: Int
        var type: ConversationType = .channel
        let name: String
        let description: String?
        let isPublic: Bool
        let isAnnouncementChannel: Bool

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/channels"
        }
    }

    func createChannel(for courseId: Int, name: String, description: String?, isPrivate: Bool, isAnnouncement: Bool) async -> DataState<Channel> {
        let result = await client.sendRequest(
            CreateChannelRequest(courseId: courseId, name: name, description: description, isPublic: !isPrivate, isAnnouncementChannel: isAnnouncement)
        )

        switch result {
        case let .success((channel, _)):
            return .done(response: channel)
        case let .failure(error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct ArchiveChannelRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let channelId: Int64

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/channels/\(channelId)/archive"
        }
    }

    func archiveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        let result = await client.sendRequest(ArchiveChannelRequest(courseId: courseId, channelId: channelId))

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    struct UnarchiveChannelRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let channelId: Int64

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/channels/\(channelId)/unarchive"
        }
    }

    func unarchiveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        let result = await client.sendRequest(UnarchiveChannelRequest(courseId: courseId, channelId: channelId))

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    func deleteChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse {
        let result = await client.sendRequest(DeleteChannelRequest(courseId: courseId, channelId: channelId))

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    struct DeleteChannelRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int
        let channelId: Int64

        var method: HTTPMethod {
            return .delete
        }

        var resourceName: String {
            return "api/courses/\(courseId)/channels/\(channelId)"
        }
    }

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
