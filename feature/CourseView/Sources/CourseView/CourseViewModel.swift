import Foundation
import SharedModels
import Common
import APIClient

@MainActor
class CourseViewModel: ObservableObject {

    @Published var course: DataState<Course> = DataState.loading

    init(courseId: Int) {
        Task {
            await loadCourse(id: courseId)
        }
    }

    func loadCourse(id: Int) async {
        self.course = await CourseServiceFactory.shared.getCourse(courseId: id)
    }
}
