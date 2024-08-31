import Common
import SwiftUI

@MainActor
public class NavigationController: ObservableObject {

    @Published public var outerPath: NavigationPath
    @Published public var tabPath: NavigationPath

    @Published public var courseTab = TabIdentifier.exercise

    @Published public var showDeeplinkNotSupported = false

    public var notSupportedUrl: URL?

    public init() {
        self.outerPath = NavigationPath()
        self.tabPath = NavigationPath()

        DeeplinkHandler.shared.setup(navigationController: self)
    }
}

public extension NavigationController {
    func popToRoot() {
        outerPath = NavigationPath()
        tabPath = NavigationPath()
    }

    func goToCourse(id: Int) {
        popToRoot()

        outerPath.append(CoursePath(id: id))
        log.debug("CoursePath was appended to queue")
    }

    func goToExercise(courseId: Int, exerciseId: Int) {
        courseTab = .exercise
        goToCourse(id: courseId)
        outerPath.append(ExercisePath(id: exerciseId, coursePath: CoursePath(id: courseId)))
        log.debug("ExercisePath was appended to queue")
    }

    func goToLecture(courseId: Int, lectureId: Int) {
        courseTab = .lecture
        goToCourse(id: courseId)
        outerPath.append(LecturePath(id: lectureId, coursePath: CoursePath(id: courseId)))
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
        outerPath.append(ConversationPath(id: conversationId, coursePath: CoursePath(id: courseId)))
    }

    func showDeeplinkNotSupported(url: URL) {
        notSupportedUrl = url
        showDeeplinkNotSupported = true
    }
}
