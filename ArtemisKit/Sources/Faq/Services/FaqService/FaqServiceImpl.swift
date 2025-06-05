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
            case faq
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(faq)
        }

        var method: HTTPMethod { .post }

        var resourceName: String {
            return "api/communication/courses/\(courseId)/faqs"
        }
    }

    func proposeFaq(faq: FaqDTO, for courseId: Int) async -> DataState<FaqDTO> {
        var newFaq = faq
        newFaq.id = nil
        newFaq.faqState = .proposed
        newFaq.course = .init(id: courseId, courseInformationSharingConfiguration: .communicationAndMessaging)

        let result = await client.sendRequest(ProposeFaqRequest(courseId: courseId, faq: newFaq))

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
