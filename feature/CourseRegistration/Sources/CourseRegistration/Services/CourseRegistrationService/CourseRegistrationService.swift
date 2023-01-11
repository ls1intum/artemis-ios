import Foundation
import Model
import Data

/**
 * Service that handles all server communication for registering to a course.
 */
public protocol CourseRegistrationService {
    /**
     * Fetch the courses the user can register to from the server.
     * Automatically retries if failed.
     */
    func fetchRegistrableCourses() async -> DataState<[Course]>

    func registerInCourse(courseId: Int) async throws
}

enum CourseRegistrationServiceFactory {
    
    static let shared: CourseRegistrationService = CourseRegistrationServiceImpl()
    
}