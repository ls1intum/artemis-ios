import Foundation
import SharedModels
import APIClient
import Common

/**
 * DashboardService implementation that requests the dashboard from the Artemis server.
 */
class DashboardServiceImpl: DashboardService {

    let client = APIClient()

    struct GetCoursesRequest: APIRequest {
        typealias Response = [CourseForDashboard]

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/courses/for-dashboard"
        }
    }

    func loadCourses() async -> DataState<[CourseForDashboard]> {
        let result = await client.sendRequest(GetCoursesRequest())

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
