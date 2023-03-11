import Foundation
import SharedModels
import APIClient
import UserStore
import Common

@MainActor
class CoursesOverviewViewModel: ObservableObject {

    @Published var courses: DataState<[Course]> = DataState.loading
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
        courses = await DashboardServiceFactory.shared.loadCourses()
    }
}
