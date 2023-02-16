import Foundation
import Model
import APIClient
import UserStore
import Common

@MainActor class CoursesOverviewViewModel: ObservableObject {

    @Published var courses: DataState<[Course]> = DataState.loading

    init() {

        Task {
            await loadCourses()
        }
    }

    func loadCourses() async {
        courses = await DashboardServiceFactory.shared.loadCourses()
    }

    func logout() {
        // TODO: move to other view
        //        accountService.logout()
        UserSession.shared.setUserLoggedIn(isLoggedIn: false, shouldRemember: false)
    }
}
