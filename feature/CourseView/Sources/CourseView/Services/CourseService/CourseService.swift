import Foundation
import SharedModels
import Common

protocol CourseService {

    func getCourse(courseId: Int) async -> DataState<CourseForDashboard>
}

enum CourseServiceFactory {

    static let shared: CourseService = CourseServiceImpl()
}
