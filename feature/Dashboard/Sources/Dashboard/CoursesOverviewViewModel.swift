import Foundation
import SharedModels
import APIClient
import UserStore
import Common

@MainActor
class CoursesOverviewViewModel: ObservableObject {

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
        coursesForDashboard = await DashboardServiceFactory.shared.loadCourses()
    }
}
