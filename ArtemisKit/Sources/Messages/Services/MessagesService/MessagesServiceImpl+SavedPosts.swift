//
//  MessagesServiceImpl+SavedPosts.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 15.03.25.
//

import APIClient
import Common

extension MessagesServiceImpl {
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
}
