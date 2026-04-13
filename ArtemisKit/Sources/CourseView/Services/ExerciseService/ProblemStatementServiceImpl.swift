//
//  ProblemStatementServiceImpl.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.04.26.
//

import APIClient
import Common

struct ProblemStatementServiceImpl: ProblemStatementService {
    let client = APIClient()

    struct GetRenderedProblemStatementRequest: APIRequest {
        typealias Response = RenderedProblemStatement

        let markdown: String
        let locale = "en"
        let darkMode: Bool
        let includeJs = false
        let includeCss = true

        var method: HTTPMethod { .post }

        var resourceName: String {
            "api/exercise/problem-statement/render"
        }
    }

    struct RenderedProblemStatement: Codable {
        let html: String?
    }

    func getRenderedProblemStatement(for markdown: String, darkMode: Bool) async -> DataState<String> {
        let result = await client.sendRequest(GetRenderedProblemStatementRequest(markdown: markdown, darkMode: darkMode))

        switch result {
        case let .success((response, _)):
            return .done(response: response.html ?? "")
        case let .failure(error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
