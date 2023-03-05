import Foundation
import SharedModels
import APIClient
import Common

@MainActor
class CourseRegistrationViewModel: ObservableObject {

    @Published var registrableCourses: DataState<[SemesterCourses]> = .loading

    init() {
        Task {
            await loadCourses()
        }
    }

    func reloadRegistrableCourses() async {
        await loadCourses()
    }

    func loadCourses() async {
        let courses = await CourseRegistrationServiceFactory.shared.fetchRegistrableCourses()
        switch courses {
        case .failure(let error):
            registrableCourses = .failure(error: error)
        case .loading:
            registrableCourses = .loading
        case .done(response: let result):
            registrableCourses = .done(response: Dictionary(grouping: result, by: { $0.semester ?? "" })
                                        .map { semester, courses in
                                            SemesterCourses(semester: semester, courses: courses)
                                        })
        }
    }

    func signUpForCourse(_ course: Course) async {

        let result = await CourseRegistrationServiceFactory.shared.registerInCourse(courseId: course.id) // TODO: wraping

        switch result {
        case .loading:
            registrableCourses = .loading
        case .failure(let error):
            registrableCourses = .failure(error: error)
        case .done(let response):
            registrableCourses = .done(response: Dictionary(grouping: response, by: { $0.semester ?? "" })
                                        .map { semester, courses in
                                            SemesterCourses(semester: semester, courses: courses)
                                        })
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
