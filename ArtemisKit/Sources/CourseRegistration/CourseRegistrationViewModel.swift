import APIClient
import Common
import Foundation
import SharedModels

@MainActor
class CourseRegistrationViewModel: ObservableObject {
    @Published var registrableCourses: DataState<[SemesterCourses]> = .loading
    @Published var isLoading = false

    @Published var error: UserFacingError? {
        didSet {
            showError = error != nil
        }
    }
    @Published var showError = false

    var successCompletion: () -> Void

    private let courseRegistrationService: CourseRegistrationService

    init(
        successCompletion: @escaping () -> Void,
        courseRegistrationService: CourseRegistrationService = CourseRegistrationServiceFactory.shared
    ) {
        self.successCompletion = successCompletion
        self.courseRegistrationService = courseRegistrationService
    }

    func reloadRegistrableCourses() async {
        await loadCourses()
    }

    func loadCourses() async {
        let courses = await courseRegistrationService.fetchRegistrableCourses()
        switch courses {
        case .failure(let error):
            registrableCourses = .failure(error: error)
        case .loading:
            registrableCourses = .loading
        case .done(response: let result):
            let courses = Dictionary(grouping: result, by: { $0.semester ?? "" }).map { semester, courses in
                SemesterCourses(semester: semester, courses: courses)
            }
            registrableCourses = .done(response: courses)
        }
    }

    func signUpForCourse(_ course: Course) async {
        let result = await courseRegistrationService.registerInCourse(courseId: course.id)
        isLoading = false

        switch result {
        case .success:
            successCompletion()
        case .failure(let error):
            let userFacingError = UserFacingError(title: error.localizedDescription)
            registrableCourses = .failure(error: userFacingError)
            self.error = userFacingError
        default:
            return
        }
    }
}

struct SemesterCourses: Identifiable {
    let semester: String
    let courses: [Course]

    var id: Int {
        semester.hash
    }
}
