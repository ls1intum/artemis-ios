import Common
import Dependencies
import Foundation
import SharedModels
import SharedServices

@MainActor
class CourseViewModel: ObservableObject {

    @Dependency(\.courseService) private var courseService

    @Published var course: DataState<Course> = DataState.loading

    init(courseId: Int) {
        Task {
            await loadCourse(id: courseId)
        }
    }

    func loadCourse(id: Int) async {
        let result = await courseService.getCourse(courseId: id)

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

// MARK: - CourseService

enum CourseServiceKey: DependencyKey {
    typealias Value = CourseService

    static var liveValue: Value {
        CourseServiceFactory.shared
    }
}

extension DependencyValues {
    var courseService: CourseService {
        get {
            self[CourseServiceKey.self]
        }
        set {
            self[CourseServiceKey.self] = newValue
        }
    }
}
