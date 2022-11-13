import Foundation

/**
 * Representation of a single course.
 */
struct Course: Decodable, Identifiable {
    let id: Int
    var title: String? = ""
    var description: String? = ""
    var courseIcon: String? = nil
    var semester: String? = ""
    var registrationConfirmationMessage: String? = ""
    var exercises: [Exercise]? = nil
}
