import Common
import SharedModels
import SwiftUI

@MainActor
public class NavigationController: ObservableObject {

    @Published public var outerPath: NavigationPath
    @Published public var selectedCourse: CoursePath?
    @Published public var lectureMediaPath: [LectureMediaPath] = []
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
        lectureMediaPath = []
        outerPath = NavigationPath()
        tabPath = NavigationPath()
        selectedCourse = nil
        selectedPath = nil
    }

    func goToCourse(id: Int) {
        if let currentCourseId = selectedCourse?.id, currentCourseId == id {
            return
        }

        popToRoot()

        selectedCourse = CoursePath(id: id)
        log.debug("CoursePath was appended to queue")
    }

    func goToExercise(courseId: Int, exerciseId: Int) {
        goToCourse(id: courseId)
        lectureMediaPath = []
        courseTab = .exercise
        selectedPath = ExercisePath(id: exerciseId, coursePath: CoursePath(id: courseId))
        log.debug("ExercisePath was appended to queue")
    }

    func goToLecture(courseId: Int, lectureId: Int, target: LectureMediaTarget? = nil) {
        if let target {
            openLectureMedia(courseId: courseId, lectureId: lectureId, target: target)
            return
        }
        goToCourse(id: courseId)
        lectureMediaPath = []
        courseTab = .lecture
        tabPath = NavigationPath()
        selectedPath = LecturePath(id: lectureId, coursePath: CoursePath(id: courseId))
        log.debug("LecturePath was appended to queue")
    }

    /// Keeps the originating course tab and detail stack intact for native Back.
    func openLectureMedia(courseId: Int, lectureId: Int, target: LectureMediaTarget? = nil) {
        if selectedCourse?.id != courseId {
            goToLecture(courseId: courseId, lectureId: lectureId)
        }
        lectureMediaPath = [LectureMediaPath(courseId: courseId, lectureId: lectureId, target: target)]
    }

    func goToIrisSession(courseId: Int, sessionId: Int, defaultInput: String = "", contextSource: IrisContextSource? = nil) {
        lectureMediaPath = []
        goToCourse(id: courseId)
        courseTab = .iris
        selectedPath = IrisSessionPath(sessionId: sessionId,
                                       defaultInput: defaultInput,
                                       contextSource: contextSource,
                                       coursePath: selectedCourse ?? CoursePath(id: courseId))
        tabPath = NavigationPath()
    }

    func openNewIrisChat(courseId: Int, inputText: String) {
        lectureMediaPath = []
        goToCourse(id: courseId)
        courseTab = .iris
        selectedPath = IrisStartChatPath(inputText: inputText, coursePath: selectedCourse ?? CoursePath(id: courseId))
        tabPath = NavigationPath()
    }

    /// Opens the Iris tab without selecting a session, e.g. to let the user pick
    /// their AI experience before a session is created.
    func goToIris(courseId: Int) {
        lectureMediaPath = []
        goToCourse(id: courseId)
        courseTab = .iris
        selectedPath = nil
        tabPath = NavigationPath()
    }

    func setTab(identifier: TabIdentifier) {
        lectureMediaPath = []
        courseTab = identifier
    }

    func goToCourseConversations(courseId: Int) {
        lectureMediaPath = []
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

    func goToThread(for messageId: Int64, in conversation: Conversation, courseId: Int) {
        tabPath.append(ThreadPath(postId: messageId, conversation: conversation, coursePath: CoursePath(id: courseId)))
    }

    func showDeeplinkNotSupported(url: URL) {
        notSupportedUrl = url
        showDeeplinkNotSupported = true
    }
}
