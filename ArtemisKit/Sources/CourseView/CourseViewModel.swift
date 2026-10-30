import Foundation
import SharedModels
import Common
import SharedServices

@Observable
class CourseViewModel: BaseViewModel {
    let course: CourseForOverviewDTO
    let availableTabs: CourseAvailableTabsDTO
    var scorePrecision = 1
    private let reviewReader: (any ReviewReading)?
    var exercisesOverview: DataState<CourseExercisesForOverviewDTO> = .loading
    var lecturesOverview: DataState<[Lecture]> = .loading

    private let courseService: CourseService

    var isMessagesVisible: Bool {
        course.courseInformationSharingConfiguration != .disabled
    }

    init(course: CourseForOverviewDTO, availableTabs: CourseAvailableTabsDTO, courseService: CourseService = CourseServiceFactory.shared, reviewReader: (any ReviewReading)? = nil) {
        self.course = course
        self.availableTabs = availableTabs
        self.courseService = courseService
        self.reviewReader = reviewReader
    }
}

extension CourseViewModel {
    func refreshExercises() async {
        let overview = await courseService.getExerciseOverview(courseId: course.id)
        let transport = ReviewSession.current().map { ReviewTransport(captured: $0) }
        defer { transport?.invalidate() }
        if let reader = reviewReader ?? transport, let precision = try? await CourseScoreMetadata.load(courseID: course.id, reader: reader) {
            scorePrecision = precision
        }
        exercisesOverview = overview
    }

    func refreshLectures() async {
        lecturesOverview = await courseService.getLectureOverview(courseId: course.id)
    }
}
