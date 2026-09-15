import Foundation
import SharedModels
import Common
import SharedServices

@MainActor
class CourseViewModel: BaseViewModel {
    @Published var course: CourseForOverviewDTO
    // TODO: Lectures+Exercises overview

    private let courseService: CourseService

    var isMessagesVisible: Bool {
        course.courseInformationSharingConfiguration != .disabled
    }

    init(course: CourseForOverviewDTO, courseService: CourseService = CourseServiceFactory.shared) {
        self.course = course
        self.courseService = courseService
    }
}

extension CourseViewModel {
    func refreshCourse() async {
        let result = await courseService.getCourse(courseId: course.id)
        switch result {
        case .loading:
            break
        case let .failure(error):
            presentError(userFacingError: error)
        case let .done(course):
            self.course = course
        }
    }
}
