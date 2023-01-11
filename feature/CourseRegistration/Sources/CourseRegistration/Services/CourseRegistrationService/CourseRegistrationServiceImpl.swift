import Foundation
import Model
import Data
import APIClient

class CourseRegistrationServiceImpl: CourseRegistrationService {

    private let client = APIClient()
    
    struct FetchRegistrableCoursesRequest: APIRequest {
        typealias Response = [Course]
        
        var method: HTTPMethod {
            return .get
        }
        
        var resourceName: String {
            return "api/courses/for-registration"
        }
    }
    
    func fetchRegistrableCourses() async -> DataState<[Course]> {
        let result = await client.send(FetchRegistrableCoursesRequest())
        
        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: error)
        }
    }
    
    struct RegisterCourseRequest: APIRequest {
        typealias Response = [Course] // TODO: change response
        
        var courseId: Int
        
        var method: HTTPMethod {
            return .post
        }
        
        var resourceName: String {
            return "api/courses/\(courseId)/register"
        }
    }
    
    func registerInCourse(courseId: Int) async throws {
        let result = await client.send(RegisterCourseRequest(courseId: courseId))
        
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
