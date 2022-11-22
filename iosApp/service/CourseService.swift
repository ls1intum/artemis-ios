import Foundation
import Model

protocol CourseService {

    func getCourse(courseId: Int, serverUrl: String, authToken: String) async -> NetworkResponse<Course>
}
