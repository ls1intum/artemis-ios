import SwiftUI
import SharedModels
import Common

@MainActor
public class NavigationController: ObservableObject {

    @Published public var path: NavigationPath

    @Published public var courseTab = TabIdentifier.exercise

    public init() {
        self.path = NavigationPath()

        DeeplinkHandler.shared.setup(navigationController: self)
    }

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
        path.append(ExercisePath(id: exerciseId,
                                 coursePath: CoursePath(id: courseId)))
        log.debug("ExercisePath was appended to queue")
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
        path.append(ConversationPath(id: conversationId,
                                     coursePath: CoursePath(id: courseId)))
    }
}

public enum TabIdentifier {
    case exercise, lecture, communication
}

public struct CoursePath: Hashable {
    public let id: Int
    public let course: Course?

    public init(id: Int) {
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

public struct ConversationPath: Hashable {
    public let id: Int64
    public let conversation: Conversation?
    public let coursePath: CoursePath

    public init(id: Int64, coursePath: CoursePath) {
        self.id = id
        self.conversation = nil
        self.coursePath = coursePath
    }

    public init(conversation: Conversation, coursePath: CoursePath) {
        self.id = conversation.id
        self.conversation = conversation
        self.coursePath = coursePath
    }
}

public struct MessagePath: Hashable {
    public let id: Int64
    public let message: Message?
    public let coursePath: CoursePath
    public let conversationPath: ConversationPath

    init(id: Int64, coursePath: CoursePath, conversationPath: ConversationPath) {
        self.id = id
        self.message = nil
        self.coursePath = coursePath
        self.conversationPath = conversationPath
    }

    public init(message: Message, coursePath: CoursePath, conversationPath: ConversationPath) {
        self.id = message.id
        self.message = message
        self.coursePath = coursePath
        self.conversationPath = conversationPath
    }
}
