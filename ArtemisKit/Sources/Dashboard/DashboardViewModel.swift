import Common
import Foundation
import SharedModels
import SharedServices
import SwiftUI

@Observable
class DashboardViewModel {

    var searchText = ""
    var coursesForDashboard: DataState<CoursesForDashboardDTO> = DataState.loading
    var filteredCourses: [CourseForDashboardDTO] {
        if searchText.isEmpty {
            coursesForDashboard.value?.courses ?? []
        } else {
            coursesForDashboard.value?.courses?.filter {
                ($0.course.title ?? "").localizedStandardContains(searchText)
            } ?? []
        }
    }

    var recentCourseIds: [Int] {
        get {
            access(keyPath: \.recentCourseIds)
            return UserDefaults.standard.array(forKey: "recentCourseIds") as? [Int] ?? []
        }
        set {
            withMutation(keyPath: \.recentCourseIds) {
                UserDefaults.standard.setValue(newValue, forKey: "recentCourseIds")
            }
        }
    }

    var recentCourses: [CourseForDashboardDTO] {
        guard let courses = coursesForDashboard.value?.courses, courses.count > 3 else {
            return []
        }
        return courses.filter { recentCourseIds.contains($0.id) }
    }

    var error: UserFacingError?
    var showError = false

    private let courseService: CourseService

    init(courseService: CourseService = CourseServiceFactory.shared) {
        self.courseService = courseService
    }

    func loadCourses() async {
        coursesForDashboard = await courseService.getCourses().map { coursesDTO in
            // Sort courses alpabetically
            var response = coursesDTO
            response.courses = response.courses?.sorted {
                $0.course.title ?? "" < $1.course.title ?? ""
            }
            return response
        }
    }

    func addToRecents(courseId: Int) {
        if recentCourseIds.contains(courseId) {
            // Remove it here and insert it back at the beginning
            // so that it will be discarded last
            recentCourseIds.removeAll { $0 == courseId }
        }
        if recentCourseIds.count >= 3 {
            recentCourseIds.removeLast()
        }
        recentCourseIds.insert(courseId, at: 0)
    }
}

// MARK: Array+RawRepresentable
// Needed for @AppStorage with a Codable array
extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let result = try? JSONDecoder().decode([Element].self, from: Data(rawValue.utf8)) else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        if let data = try? JSONEncoder().encode(self),
           let result = String(data: data, encoding: .utf8) {
            return result
        }
        return "[]"
    }
}
