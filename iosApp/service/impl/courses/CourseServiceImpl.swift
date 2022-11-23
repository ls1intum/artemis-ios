import Foundation
import Alamofire
import Model
import Data

class CourseServiceImpl: CourseService {

    private let jsonProvider: JsonProvider

    init(jsonProvider: JsonProvider) {
        self.jsonProvider = jsonProvider
    }

    func getCourse(courseId: Int, serverUrl: String, authToken: String) async -> NetworkResponse<Course> {
        await performNetworkCall {
            let headers: HTTPHeaders = [
                .contentType(ContentTypes.Application.Json),
                .authorization(bearerToken: authToken),
                .defaultUserAgent
            ]

            return try await AF
                    .request(
                            serverUrl + "api/courses/" + String(courseId) + "/for-dashboard",
                            headers: headers
                    )
                    .serializingDecodable(Course.self, decoder: jsonProvider.decoder)
                    .value
        }
    }
}
