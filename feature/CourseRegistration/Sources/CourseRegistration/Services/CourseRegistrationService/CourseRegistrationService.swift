import Foundation
import SharedModels
import Common

/**
 * Service that handles all server communication for registering to a course.
 */
public protocol CourseRegistrationService {
    /**
     * Fetch the courses the user can register to from the server.
     * Automatically retries if failed.
     */
    func fetchRegistrableCourses() async -> DataState<[Course]>

    func registerInCourse(courseId: Int) async -> DataState<[Course]>
}

enum CourseRegistrationServiceFactory {

    static let shared: CourseRegistrationService = CourseRegistrationServiceImpl()

}
