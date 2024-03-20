import Common
import SwiftUI

@MainActor
public class NavigationController: ObservableObject {

    @Published public var path: NavigationPath

    @Published public var courseTab = TabIdentifier.exercise

    @Published public var showDeeplinkNotSupported = false

    public var notSupportedUrl: URL?

    public init() {
        self.path = NavigationPath()

        DeeplinkHandler.shared.setup(navigationController: self)
    }
}

public extension NavigationController {
    func popToRoot() {
        path = NavigationPath()
    }

    func goToCourse(id: Int) {
        popToRoot()

        path.append(CoursePath(id: id))
        log.debug("CoursePath was appended to queue")
    }

    func goToExercise(courseId: Int, exerciseId: Int) {
        courseTab = .exercise
        goToCourse(id: courseId)
        path.append(ExercisePath(id: exerciseId, coursePath: CoursePath(id: courseId)))
        log.debug("ExercisePath was appended to queue")
    }

    func goToLecture(courseId: Int, lectureId: Int) {
        courseTab = .lecture
        goToCourse(id: courseId)
        path.append(LecturePath(id: lectureId, coursePath: CoursePath(id: courseId)))
        log.debug("LecturePath was appended to queue")
    }

    func setTab(identifier: TabIdentifier) {
        courseTab = identifier
    }

    func goToCourseConversations(courseId: Int) {
        courseTab = .communication
        goToCourse(id: courseId)
    }

    func goToCourseConversation(courseId: Int, conversationId: Int64) {
        goToCourseConversations(courseId: courseId)
        path.append(ConversationPath(id: conversationId, coursePath: CoursePath(id: courseId)))
    }

    func showDeeplinkNotSupported(url: URL) {
        notSupportedUrl = url
        showDeeplinkNotSupported = true
    }

    // MARK: General

    var count: Int {
        path.count
    }

    func append<V: Hashable>(_ value: V) {
        path.append(value)
    }

    func removeLast() {
        path.removeLast()
    }
}
