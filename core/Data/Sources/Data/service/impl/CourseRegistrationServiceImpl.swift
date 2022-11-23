import Foundation
import Alamofire
import Model
import Data

class CourseRegistrationServiceImpl: CourseRegistrationService {

    private let jsonProvider: JsonProvider

    init(jsonProvider: JsonProvider) {
        self.jsonProvider = jsonProvider
    }

    func fetchRegistrableCourses(serverUrl: String, authToken: String) async -> NetworkResponse<[Course]> {
        let headers: HTTPHeaders = [
            .accept(ContentTypes.Application.Json),
            .defaultUserAgent,
            .authorization(bearerToken: authToken)
        ]

        return await performNetworkCall {
            try await AF.request(serverUrl + "api/courses/for-registration")
                    .serializingDecodable([Course].self)
                    .value
        }
    }

    func registerInCourse(serverUrl: String, authToken: String, courseId: Int) async -> NetworkResponse<()> {
        let headers: HTTPHeaders = [
            .defaultUserAgent,
            .authorization(bearerToken: authToken)
        ]

        return await performNetworkCall {
            try await AF.request(serverUrl + "api/courses/for-registration", method: .post)
                    .serializingDecodable(Account.self)
                    .value
        }.bind(f: { () })
    }
}
