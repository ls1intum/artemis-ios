import Foundation

/**
 * Representation of a single course.
 */
public struct Course: Decodable, Identifiable {
    public var id: Int? = nil
    public var title: String? = ""
    public var description: String? = ""
    public var courseIcon: String? = nil
    public var semester: String? = ""
    public var registrationConfirmationMessage: String? = ""
    public var exercises: [Exercise]? = nil

    public init(id: Int? = nil, title: String? = "", description: String? = "", courseIcon: String? = nil, semester: String? = "", registrationConfirmationMessage: String? = "", exercises: [Exercise]? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.courseIcon = courseIcon
        self.semester = semester
        self.registrationConfirmationMessage = registrationConfirmationMessage
        self.exercises = exercises
    }
}
