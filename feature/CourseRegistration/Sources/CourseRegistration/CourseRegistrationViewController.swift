import Foundation
import SwiftUI
import Factory
import RxSwift
import Model
import Device
import APIClient
import UI
import Common

@MainActor class CourseRegistrationViewController: ObservableObject {

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
        case .suspended(let error):
            registrableCourses = .suspended(error: error)
        }
    }
}

struct SemesterCourses: Identifiable {
    let semester: String
    let courses: [Course]

    var id: Int {
        get {
            semester.hash
        }
    }
}
