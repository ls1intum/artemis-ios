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

    public init(id: Int, course: Course) {
        self.id = id
        self.course = course
    }
}
