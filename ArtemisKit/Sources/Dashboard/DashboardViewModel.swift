import Common
import Foundation
import SharedModels
import SharedServices
import UserStore

@MainActor
class DashboardViewModel: ObservableObject {

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
        coursesForDashboard = await CourseServiceFactory.shared.getCourses()
    }
}
