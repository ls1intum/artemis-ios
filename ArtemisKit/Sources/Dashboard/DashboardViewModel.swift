import Common
import Foundation
import SharedModels
import SharedServices

class DashboardViewModel: BaseViewModel {

    @Published var coursesForDashboard: DataState<CoursesForDashboardDTO> = DataState.loading

    private let courseService: CourseService

    init(courseService: CourseService = CourseServiceFactory.shared) {
        self.courseService = courseService

        super.init()
    }

    func loadCourses() async {
        coursesForDashboard = await courseService.getCourses()
    }
}
