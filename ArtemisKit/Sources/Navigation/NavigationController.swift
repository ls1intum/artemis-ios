import Common
import SharedModels
import SwiftUI

@MainActor
public class NavigationController: ObservableObject {

    @Published public var outerPath: NavigationPath
    @Published public var selectedCourse: CoursePath?
    @Published public var tabPath: NavigationPath
    @Published public var selectedPath: (any Hashable)?

    @Published public var courseTab = TabIdentifier.exercise

    @Published public var showDeeplinkNotSupported = false

    public var notSupportedUrl: URL?

    public init() {
        self.outerPath = NavigationPath()
        self.tabPath = NavigationPath()

        DeeplinkHandler.shared.setup(navigationController: self)
    }

    /// Converts ``selectedPath`` into a `Binding` for use in a List Selection.
    /// Usage:
    /// ```swift
    /// private var selectedConversation: Binding<ConversationPath?> {
    ///     navController.selectedPathBinding($navController.selectedPath)
    /// }
    /// …
    /// List(selection: selectedConversation, …)
    /// ```
    public func selectedPathBinding<T: Hashable>(_ selectedPath: Binding<(any Hashable)?>) -> Binding<T?> {
        Binding {
            selectedPath.wrappedValue as? T
        } set: { newValue in
            selectedPath.wrappedValue = newValue
        }
    }
}

public extension NavigationController {
    func popToRoot() {
        outerPath = NavigationPath()
        tabPath = NavigationPath()
        selectedCourse = nil
        selectedPath = nil
    }

    func goToCourse(id: Int) {
        popToRoot()

        selectedCourse = CoursePath(id: id)
        log.debug("CoursePath was appended to queue")
    }

    func goToExercise(courseId: Int, exerciseId: Int) {
        courseTab = .exercise
        goToCourse(id: courseId)
        selectedPath = ExercisePath(id: exerciseId, coursePath: CoursePath(id: courseId))
        log.debug("ExercisePath was appended to queue")
    }

    func goToLecture(courseId: Int, lectureId: Int) {
        courseTab = .lecture
        goToCourse(id: courseId)
        selectedPath = LecturePath(id: lectureId, coursePath: CoursePath(id: courseId))
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
        selectedPath = ConversationPath(id: conversationId, coursePath: CoursePath(id: courseId))
        tabPath = NavigationPath()
    }

    func goToCourseConversation(courseId: Int, conversation: Conversation) {
        goToCourseConversations(courseId: courseId)
        selectedPath = ConversationPath(conversation: conversation, coursePath: CoursePath(id: courseId))
        tabPath = NavigationPath()
    }

    func goToThread(for messageId: Int64, in conversation: Conversation, of course: Course) {
        tabPath.append(ThreadPath(postId: messageId, conversation: conversation, coursePath: CoursePath(course: course)))
    }

    func showDeeplinkNotSupported(url: URL) {
        notSupportedUrl = url
        showDeeplinkNotSupported = true
    }
}
