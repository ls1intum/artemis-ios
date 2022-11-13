import Foundation

/**
 * A dashboard is a collection of courses.
 */
struct Dashboard: Decodable {
    let courses: [Course]
}
