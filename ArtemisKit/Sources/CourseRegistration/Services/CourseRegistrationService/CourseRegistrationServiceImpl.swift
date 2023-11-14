import Foundation
import SharedModels
import APIClient
import Common

class CourseRegistrationServiceImpl: CourseRegistrationService {

    private let client = APIClient()

    struct FetchRegistrableCoursesRequest: APIRequest {
        typealias Response = [Course]

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/courses/for-enrollment"
        }
    }

    func fetchRegistrableCourses() async -> DataState<[Course]> {
        let result = await client.sendRequest(FetchRegistrableCoursesRequest())

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct RegisterCourseRequest: APIRequest {
        typealias Response = RawResponse

        var courseId: Int

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/courses/\(courseId)/enroll"
        }
    }

    func registerInCourse(courseId: Int) async -> NetworkResponse {
        let result = await client.sendRequest(RegisterCourseRequest(courseId: courseId))

        switch result {
        case .success((let response, _)):
            return .success
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
