import Foundation
import SharedModels
import Common
import SharedServices

@MainActor
class CourseViewModel: BaseViewModel {
    @Published var course: CourseForOverviewDTO
    @Published var exercisesOverview: DataState<CourseExercisesForOverviewDTO> = .loading
    @Published var lecturesOverview: DataState<CourseLecturesForOverviewDTO> = .loading

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

    func refreshExercises() async {
        exercisesOverview = await courseService.getExerciseOverview(courseId: course.id)
    }

    func refreshLectures() async {
        lecturesOverview = await courseService.getLectureOverview(courseId: course.id)
    }
}
