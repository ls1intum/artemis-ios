import Foundation
import Alamofire
import Model
import RxSwift
import Device

class CourseRegistrationServiceImpl: CourseRegistrationService {

    private let jsonProvider: JsonProvider
    private let networkStatusProvider: NetworkStatusProvider

    init(jsonProvider: JsonProvider, networkStatusProvider: NetworkStatusProvider) {
        self.jsonProvider = jsonProvider
        self.networkStatusProvider = networkStatusProvider
    }

    func fetchRegistrableCourses(serverUrl: String, authToken: String) -> Observable<DataState<[Course]>> {
        retryOnInternet(connectivity: networkStatusProvider.currentNetworkStatus) {
            await performNetworkCall {
                let headers: HTTPHeaders = [
                    .accept(ContentTypes.Application.Json),
                    .defaultUserAgent,
                    .authorization(bearerToken: authToken)
                ]
                return try await AF.request(serverUrl + "api/courses/for-registration", headers: headers)
                        .serializingDecodable([Course].self)
                        .value
            }
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
        }
                .bind(f: { () })
    }
}
