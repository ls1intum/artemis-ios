import Foundation
import Model

public protocol CourseService {

    func getCourse(courseId: Int, serverUrl: String, authToken: String) async -> NetworkResponse<Course>
}
