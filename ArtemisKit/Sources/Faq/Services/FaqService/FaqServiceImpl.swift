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
            return "api/communication/courses/\(courseId)/faqs"
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

    struct GetFaqRequest: APIRequest {
        typealias Response = FaqDTO

        let courseId: Int
        let faqId: Int64

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/faqs/\(faqId)"
        }
    }

    func getFaq(with faqId: Int64, for courseId: Int) async -> DataState<FaqDTO> {
        let result = await client.sendRequest(GetFaqRequest(courseId: courseId, faqId: faqId))

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct ProposeFaqRequest: APIRequest {
        typealias Response = FaqDTO

        let courseId: Int
        let faq: FaqDTO

        enum CodingKeys: CodingKey {
            case courseId
            case questionTitle
            case questionAnswer
            case categories
            case faqState
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(courseId, forKey: .courseId)
            try container.encode(faq.questionTitle, forKey: .questionTitle)
            try container.encode(faq.questionAnswer, forKey: .questionAnswer)
            try container.encode(faq.categories, forKey: .categories)
            try container.encode(faq.faqState, forKey: .faqState)
        }

        var method: HTTPMethod { .post }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/faqs"
        }
    }

    func proposeFaq(faq: FaqDTO, for courseId: Int) async -> DataState<FaqDTO> {
        var newFaq = faq
        newFaq.faqState = .proposed

        let result = await client.sendRequest(ProposeFaqRequest(courseId: courseId, faq: newFaq))

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
