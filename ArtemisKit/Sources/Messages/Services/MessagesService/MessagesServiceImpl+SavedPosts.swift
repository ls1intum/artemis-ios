//
//  MessagesServiceImpl+SavedPosts.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 15.03.25.
//

import APIClient
import Common

extension MessagesServiceImpl {
    struct AddSavedPostRequest: APIRequest {
        typealias Response = RawResponse

        let postId: Int
        let postType: PostType

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/communication/saved-posts/\(postId)/\(postType)"
        }
    }

    func addSavedPost(with postId: Int, of type: PostType) async -> NetworkResponse {
        let result = await client.sendRequest(AddSavedPostRequest(postId: postId, postType: type))

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    struct GetSavedPostsRequest: APIRequest {
        typealias Response = [SavedPostDTO]

        let courseId: Int
        let status: SavedPostStatus

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/communication/saved-posts/\(courseId)/\(status.rawValue)"
        }
    }

    func getSavedPosts(for courseId: Int, status: SavedPostStatus) async -> DataState<[SavedPostDTO]> {
        let result = await client.sendRequest(GetSavedPostsRequest(courseId: courseId, status: status))

        switch result {
        case .success(let response):
            return .done(response: response.0)
        case let .failure(error):
            return .failure(error: .init(error: error))
        }
    }

    struct UpdateSavedPostStatusRequest: APIRequest {
        typealias Response = RawResponse

        let postId: Int
        let postType: PostType
        let status: SavedPostStatus

        var method: HTTPMethod {
            return .put
        }

        var resourceName: String {
            return "api/communication/saved-posts/\(postId)/\(postType.rawValue)?status=\(status.rawValue)"
        }
    }

    func updateSavedPostStatus(for postId: Int, with type: PostType, status: SavedPostStatus) async -> NetworkResponse {
        let result = await client.sendRequest(UpdateSavedPostStatusRequest(postId: postId, postType: type, status: status))

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }

    struct DeleteSavedPostRequest: APIRequest {
        typealias Response = RawResponse

        let postId: Int
        let postType: PostType

        var method: HTTPMethod {
            return .delete
        }

        var resourceName: String {
            return "api/communication/saved-posts/\(postId)/\(postType.rawValue)"
        }
    }

    func deleteSavedPost(with postId: Int, of type: PostType) async -> NetworkResponse {
        let result = await client.sendRequest(DeleteSavedPostRequest(postId: postId, postType: type))

        switch result {
        case .success:
            return .success
        case let .failure(error):
            return .failure(error: error)
        }
    }
}
