import Common
import Foundation
import SharedModels
import SharedServices
import SwiftUI

class DashboardViewModel: BaseViewModel {

    @Published var coursesForDashboard: DataState<CoursesForDashboardDTO> = DataState.loading

    @AppStorage("recentCourseIds")
    var recentCourseIds = [Int]()

    private let courseService: CourseService

    init(courseService: CourseService = CourseServiceFactory.shared) {
        self.courseService = courseService

        super.init()
    }

    func loadCourses() async {
        coursesForDashboard = await courseService.getCourses()
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
