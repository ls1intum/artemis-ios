//
//  SearchServiceImpl.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 21.03.26.
//

import APIClient
import Common
import Foundation

struct SearchServiceImpl: SearchService {
    let client = APIClient()

    struct SearchAPIRequest: APIRequest {
        typealias Response = [SearchResultDTO]

        let types: [SearchFilterType]?
        let courseId: Int?
        let searchTerm: String

        var resourceName: String {
            "api/search"
        }

        var method: HTTPMethod { .get }

        var params: [URLQueryItem] {
            [
                .init(name: "q", value: searchTerm),
                .init(name: "courseId", value: courseId.flatMap { "\($0)" }),
                .init(name: "types", value: types?.map(\.apiType).joined(separator: ","))
            ]
        }
    }

    func search(for types: [SearchFilterType]?, in courseId: Int?, searchTerm: String) async -> DataState<[SearchResultDTO]> {
        let request = SearchAPIRequest(types: types, courseId: courseId, searchTerm: searchTerm)

        let result = await client.sendRequest(request)

        switch result {
        case .success(let response):
            return .done(response: response.0)
        case .failure(let error):
            return .failure(error: .init(error: error))
        }
    }
}
