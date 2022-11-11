import Foundation
import Alamofire

/**
 * DashboardService implementation that requests the dashboard from the Artemis server.
 */
class DashboardServiceImpl: DashboardService {

    let jsonProvider: JsonProvider

    init(jsonProvider: JsonProvider) {
        self.jsonProvider = jsonProvider
    }

    func loadDashboard(authorizationToken: String, serverUrl: String) async -> NetworkResponse<Dashboard> {
        let headers: HTTPHeaders = [
            .accept(ContentTypes.Application.Json),
            .defaultUserAgent,
            .authorization(bearerToken: authorizationToken)
        ]

        return await performNetworkCall {
            try await AF.request(serverUrl + "api/courses/for-dashboard")
                    .serializingDecodable([Course].self)
                    .value
        }
                .bind { courses in
                    Dashboard(courses: courses)
                }
    }
}
