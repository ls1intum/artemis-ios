//
//  FaqServiceImpl.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.10.24.
//

import APIClient
import Common
import SharedModels

struct FaqServiceImpl: FaqService {

    let client = APIClient()

    struct GetFaqsRequest: APIRequest {
        typealias Response = [FaqDTO]

        let courseId: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/courses/\(courseId)/faqs"
        }
    }

    func getFaqs(for courseId: Int) async -> DataState<[FaqDTO]> {
        let result = await client.sendRequest(GetFaqsRequest(courseId: courseId))

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
