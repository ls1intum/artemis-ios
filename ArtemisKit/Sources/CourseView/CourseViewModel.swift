import Foundation
import SharedModels
import Common
import SharedServices

@Observable
class CourseViewModel: BaseViewModel {
    let course: CourseForOverviewDTO
    let availableTabs: CourseAvailableTabsDTO
    var exercisesOverview: DataState<CourseExercisesForOverviewDTO> = .loading
    var lecturesOverview: DataState<[Lecture]> = .loading

    private let courseService: CourseService

    var isMessagesVisible: Bool {
        course.courseInformationSharingConfiguration != .disabled
    }

    init(course: CourseForOverviewDTO, availableTabs: CourseAvailableTabsDTO, courseService: CourseService = CourseServiceFactory.shared) {
        self.course = course
        self.availableTabs = availableTabs
        self.courseService = courseService
    }
}

extension CourseViewModel {
    func refreshExercises() async {
        exercisesOverview = await courseService.getExerciseOverview(courseId: course.id)
    }

    func refreshLectures() async {
        lecturesOverview = await courseService.getLectureOverview(courseId: course.id)
    }
}
