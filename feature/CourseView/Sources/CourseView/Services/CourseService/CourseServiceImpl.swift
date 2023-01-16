import Foundation
import Model
import APIClient
import Common

class CourseServiceImpl: CourseService {

    let client = APIClient()
    
    struct GetCoursesRequest: APIRequest {
        typealias Response = Course
        
        var courseId: Int
        
        var method: HTTPMethod {
            return .get
        }
        
        var resourceName: String {
            return "api/courses/\(courseId)/for-dashboard"
        }
    }
    
    func getCourse(courseId: Int) async -> DataState<Course> {
        let result = await client.send(GetCoursesRequest(courseId: courseId))
        
        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: error)
        }
    }
}
