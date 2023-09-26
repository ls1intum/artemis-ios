import Foundation
import SharedModels
import Common
import SharedServices

@MainActor
class CourseViewModel: ObservableObject {

    @Published var course: DataState<Course> = DataState.loading

    init(courseId: Int) {
        Task {
//            await loadCourse(id: courseId)
        }
    }

    func loadCourse(id: Int) async {
        let result = await CourseServiceFactory.shared.getCourse(courseId: id)

        switch result {
        case .loading:
            course = .loading
        case .failure(let error):
            course = .failure(error: error)
        case .done(let response):
            course = .done(response: response.course)
        }
    }
}
