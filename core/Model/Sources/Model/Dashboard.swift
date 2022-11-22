import Foundation

/**
 * A dashboard is a collection of courses.
 */
public struct Dashboard: Decodable {
    public let courses: [Course]

    public init(courses: [Course]) {
        self.courses = courses
    }
}