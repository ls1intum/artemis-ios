import Foundation
import Data
import Model

@MainActor class CoursesOverviewViewModel: ObservableObject {

    @Published var dashboard: DataState<Dashboard> = DataState.loading

    init() {
        
        Task {
            await loadCourses()
        }
    }

    func loadCourses() async {
        await DashboardServiceFactory.shared.loadCourses()
    }

    func logout() {
        // TODO: move to other view
//        accountService.logout()
    }
}
