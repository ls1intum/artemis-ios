import Foundation
import Common
import UserStore

/**
 * Representation of a single course.
 */
public struct Course: Decodable, Identifiable {
    public var id: Int
    public var title: String? = ""
    public var description: String? = ""
    public var courseIcon: String?
    public var semester: String? = ""
    public var registrationConfirmationMessage: String? = ""
    public var exercises: [Exercise]?
    public var lectures: [Lecture]?

    public init(id: Int, title: String? = "", description: String? = "", courseIcon: String? = nil, semester: String? = "", registrationConfirmationMessage: String? = "", exercises: [Exercise]? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.courseIcon = courseIcon
        self.semester = semester
        self.registrationConfirmationMessage = registrationConfirmationMessage
        self.exercises = exercises
    }

    public var courseIconURL: URL? {
        guard let courseIcon = courseIcon else { return nil }
        return URL(string: courseIcon, relativeTo: UserSession.shared.institution?.baseURL)
    }
}

extension Course: Hashable {
    public static func == (lhs: Course, rhs: Course) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
