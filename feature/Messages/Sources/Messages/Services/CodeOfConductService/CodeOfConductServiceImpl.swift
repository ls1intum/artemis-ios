//
//  CodeOfConductServiceImpl.swift
//
//
//  Created by Nityananda Zbil on 26.10.23.
//

import APIClient
import Common

class CodeOfConductServiceImpl: CodeOfConductService {

    private let client = APIClient()

    struct GetCodeOfConductTemplateRequest: APIRequest {
        typealias Response = RawResponse

        var method: HTTPMethod { .get }

        var resourceName: String {
            "api/files/templates/code-of-conduct"
        }
    }

    func getCodeOfConductTemplate() async -> DataState<String> {
        let result = await client.sendRequest(GetCodeOfConductTemplateRequest())
        switch result {
        case .success((let rawResponse, _)):
            return .done(response: rawResponse.rawData)
        case .failure(let error):
            return .failure(error: .init(error: error))
        }
    }

    struct GetCodeOfConductAgreementRequest: APIRequest {
        typealias Response = Bool

        let courseId: Int

        var method: HTTPMethod { .get }
        var resourceName: String { "api/courses/\(courseId)/code-of-conduct/agreement"}
    }

    func getCodeOfConductAgreement(for courseId: Int) async -> DataState<Bool> {
        let result = await client.sendRequest(GetCodeOfConductAgreementRequest(courseId: courseId))
        switch result {
        case .success(let (value, _)):
            return .done(response: value)
        case .failure(let error):
            return .init(error: error)
        }
    }

    struct AcceptCodeOfConductRequest: APIRequest {
        typealias Response = RawResponse

        let courseId: Int

        var method: HTTPMethod { .patch }
        var resourceName: String { "api/courses/\(courseId)/code-of-conduct/agreement"}
    }

    func acceptCodeOfConduct(for courseId: Int) async -> NetworkResponse {
        let result = await client.sendRequest(AcceptCodeOfConductRequest(courseId: courseId))
        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: error)
        }
    }

    struct GetCodeOfConductResponsibleUsersRequest: APIRequest {
        typealias Response = [ResponsibleUserDTO]

        let courseId: Int

        var method: HTTPMethod { .get }
        var resourceName: String { "api/courses/\(courseId)/code-of-conduct/responsible-users" }
    }

    func getCodeOfConductResponsibleUsers(for courseId: Int) async -> DataState<[ResponsibleUserDTO]> {
        let result = await client.sendRequest(GetCodeOfConductResponsibleUsersRequest(courseId: courseId))
        switch result {
        case .success(let (users, _)):
            return .done(response: users)
        case .failure(let error):
            return .init(error: error)
        }
    }
}
