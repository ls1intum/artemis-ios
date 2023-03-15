import Foundation
import Common
import UserStore
import DesignLibrary
import SwiftUI

/**
 * Representation of a single course.
 */
public struct Course: Decodable, Identifiable {
    public var id: Int
    public var title: String? = ""
    public var description: String? = ""
    public var courseIcon: String?
    public var color: String?
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
        guard let courseIcon else { return nil }
        return URL(string: courseIcon, relativeTo: UserSession.shared.institution?.baseURL)
    }

    public var courseColor: Color {
        guard let color else {
            return Color.Artemis.artemisBlue
        }
        return UIColor(hexString: color).suColor
    }

    /// Returns all exercises which have no due date or a due date in the future
    public var upcomingExercises: [Exercise] {
        return (exercises ?? [])
            .filter { exercise in
                guard let dueDate = exercise.baseExercise.dueDate else {
                    return true
                }
                return dueDate > Date.now
            }
            .sorted(by: { exerciseA, exerciseB in
                if let dueDateA = exerciseA.baseExercise.dueDate,
                   let dueDateB = exerciseB.baseExercise.dueDate {
                    return dueDateA < dueDateB
                } else if exerciseA.baseExercise.dueDate != nil {
                    return true
                } else {
                    return false
                }
            })
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
