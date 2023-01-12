import Foundation
import Model
import Data

protocol CourseService {

    func getCourse(courseId: Int) async -> DataState<Course>
}


enum CourseServiceFactory {
    
    static let shared: CourseService = CourseServiceImpl()
    
}
