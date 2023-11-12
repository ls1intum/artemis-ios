import SwiftUI
import SharedModels
import Common

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
    
    public func popToRoot() {
        path = NavigationPath()
    }
    
    public func goToCourse(id: Int) {
        popToRoot()
        
        path.append(CoursePath(id: id))
        log.debug("CoursePath was appended to queue")
    }
    
    public func goToExercise(courseId: Int, exerciseId: Int) {
        courseTab = .exercise
        goToCourse(id: courseId)
        path.append(ExercisePath(id: exerciseId,
                                 coursePath: CoursePath(id: courseId)))
        log.debug("ExercisePath was appended to queue")
    }
    
    public func goToLecture(courseId: Int, lectureId: Int) {
        courseTab = .lecture
        goToCourse(id: courseId)
        path.append(LecturePath(id: lectureId,
                                coursePath: CoursePath(id: courseId)))
        log.debug("LecturePath was appended to queue")
    }
    
    public func setTab(identifier: TabIdentifier) {
        courseTab = identifier
    }
    
    public func goToCourseConversations(courseId: Int) {
        courseTab = .communication
        goToCourse(id: courseId)
    }
    
    public func goToCourseConversation(courseId: Int, conversationId: Int64) {
        goToCourseConversations(courseId: courseId)
        path.append(ConversationPath(id: conversationId,
                                     coursePath: CoursePath(id: courseId)))
    }
    
    public func showDeeplinkNotSupported(url: URL) {
        notSupportedUrl = url
        showDeeplinkNotSupported = true
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

public struct LecturePath: Hashable {
    public let id: Int
    public let lecture: Lecture?
    public let coursePath: CoursePath
    
    init(id: Int, coursePath: CoursePath) {
        self.id = id
        self.lecture = nil
        self.coursePath = coursePath
    }
    
    public init(lecture: Lecture, coursePath: CoursePath) {
        self.id = lecture.id
        self.lecture = lecture
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
    public let message: Binding<DataState<BaseMessage>>?
    public let coursePath: CoursePath
    public let conversationPath: ConversationPath
    public let conversationViewModel: Any?
    
    init(id: Int64, coursePath: CoursePath, conversationPath: ConversationPath) {
        self.id = id
        self.message = nil
        self.coursePath = coursePath
        self.conversationPath = conversationPath
        self.conversationViewModel = nil
    }
    
    public init?(message: Binding<DataState<BaseMessage>>, coursePath: CoursePath, conversationPath: ConversationPath, conversationViewModel: Any) {
        guard let id = message.wrappedValue.value?.id else { return nil }
        self.id = id
        self.message = message
        self.coursePath = coursePath
        self.conversationPath = conversationPath
        self.conversationViewModel = conversationViewModel
    }
    
    public static func == (lhs: MessagePath, rhs: MessagePath) -> Bool {
        lhs.id == rhs.id && lhs.coursePath == rhs.coursePath && lhs.conversationPath == rhs.conversationPath
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
