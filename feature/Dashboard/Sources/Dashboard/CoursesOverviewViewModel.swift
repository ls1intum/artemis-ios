import Foundation
import SharedModels
import SharedServices
import UserStore
import Common
import Dependencies

@MainActor
class CoursesOverviewViewModel: ObservableObject {

    @Dependency(\.courseService) private var courseService

    @Published var coursesForDashboard: DataState<[CourseForDashboard]> = DataState.loading
    @Published var error: UserFacingError? {
        didSet {
            showError = error != nil
        }
    }
    @Published var showError = false

    init() {
        Task {
            await loadCourses()
        }
    }

    func loadCourses() async {
        coursesForDashboard = await courseService.getCourses()
    }

    func courseIconURL(for course: Course) -> URL? {
        courseService.courseIconURL(for: course)
    }
}
