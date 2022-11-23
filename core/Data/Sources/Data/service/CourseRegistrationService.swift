import Foundation
import Model
import RxSwift

/**
 * Service that handles all server communication for registering to a course.
 */
public protocol CourseRegistrationService {
    /**
     * Fetch the courses the user can register to from the server.
     * Automatically retries if failed.
     */
    func fetchRegistrableCourses(serverUrl: String, authToken: String) -> Observable<DataState<[Course]>>

    func registerInCourse(serverUrl: String, authToken: String, courseId: Int) async -> NetworkResponse<Void>
}
