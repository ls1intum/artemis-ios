import Foundation
import SharedModels
import Common
import SharedServices

@MainActor
class CourseViewModel: BaseViewModel {
    @Published var course: Course

    private let courseService: CourseService

    var isMessagesVisible: Bool {
        course.courseInformationSharingConfiguration == .communicationAndMessaging
        || course.courseInformationSharingConfiguration == .messagingOnly
    }

    init(course: Course, courseService: CourseService = CourseServiceFactory.shared) {
        self.course = course
        self.courseService = courseService
    }
}

extension CourseViewModel {
    func refreshCourse(id: Int) async {
        let result = await courseService.getCourse(courseId: id)
        switch result {
        case .loading:
            break
        case let .failure(error):
            presentError(userFacingError: error)
        case let .done(course):
            self.course = course.course
        }
    }
}
