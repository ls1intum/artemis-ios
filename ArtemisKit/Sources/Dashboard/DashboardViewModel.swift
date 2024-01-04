import Common
import Foundation
import SharedModels
import SharedServices

class DashboardViewModel: BaseViewModel {

    @Published var coursesForDashboard: DataState<CoursesForDashboardDTO> = DataState.loading

    override init() {
        super.init()

        Task {
            await loadCourses()
        }
    }

    func loadCourses() async {
        coursesForDashboard = await CourseServiceFactory.shared.getCourses()
    }
}
