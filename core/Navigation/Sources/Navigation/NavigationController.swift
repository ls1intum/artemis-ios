import SwiftUI
import SharedModels

public class NavigationController: ObservableObject {

    @Published public var path: NavigationPath

    @Published public var courseTab = TabIdentifier.exercise

    public init(path: NavigationPath) {
        self.path = path

        DeeplinkHandler.shared.setup(navigationController: self)
    }

    func setCourse(id: Int) {
        path.removeLast(path.count)

        path.append(CoursePath(id: id))
    }

    func setTab(identifier: TabIdentifier) {
        courseTab = identifier
    }
}

public enum TabIdentifier {
    case exercise, lecture, communication
}

public struct CoursePath: Hashable {
    public let id: Int
    public let course: Course?

    init(id: Int) {
        self.id = id
        self.course = nil
    }

    public init(course: Course) {
        self.id = course.id
        self.course = course
    }
}

public struct ExercisePath: Hashable {
    public let id: Int
    public let exercise: Exercise?
    public let coursePath: CoursePath

    init(id: Int, coursePath: CoursePath) {
        self.id = id
        self.exercise = nil
        self.coursePath = coursePath
    }

    public init(exercise: Exercise, coursePath: CoursePath) {
        self.id = exercise.id
        self.exercise = exercise
        self.coursePath = coursePath
    }
}
