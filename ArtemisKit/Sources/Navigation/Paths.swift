//
//  NavigationPathValues.swift
//
//
//  Created by Nityananda Zbil on 26.02.24.
//

import SharedModels

public struct CoursePath: Hashable, Identifiable {
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

    public init(id: Int, coursePath: CoursePath) {
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

    public init(id: Int, coursePath: CoursePath) {
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
    public let filterToUnresolved: Bool

    public init(id: Int64, coursePath: CoursePath, filterToUnresolved: Bool = false) {
        self.id = id
        self.conversation = nil
        self.coursePath = coursePath
        self.filterToUnresolved = filterToUnresolved
    }

    public init(conversation: Conversation, coursePath: CoursePath, filterToUnresolved: Bool = false) {
        self.id = conversation.id
        self.conversation = conversation
        self.coursePath = coursePath
        self.filterToUnresolved = filterToUnresolved
    }
}

public struct ThreadPath: Hashable {
    public let postId: Int64
    public let conversation: Conversation
    public let coursePath: CoursePath

    public init(postId: Int64, conversation: Conversation, coursePath: CoursePath) {
        self.postId = postId
        self.conversation = conversation
        self.coursePath = coursePath
    }
}

/// The already-resolved Iris context an "Ask Iris" button opened a session for,
/// carried across the module boundary as primitives — the Iris module rebuilds its
/// `SessionContext` from it (that type can't be named here). Mirrors `SessionContext`
/// one-to-one; `modeRawValue` stands in for its `IrisChatMode`, which also lives in Iris.
public struct IrisContextSource: Hashable {
    public let modeRawValue: String
    public let entityId: Int
    public let entityName: String?

    public init(modeRawValue: String, entityId: Int, entityName: String?) {
        self.modeRawValue = modeRawValue
        self.entityId = entityId
        self.entityName = entityName
    }
}

public struct IrisSessionPath: Hashable {
    public let sessionId: Int
    public let defaultInput: String
    public let coursePath: CoursePath
    /// A context to pre-select when the chat opens, e.g. from an "Ask Iris" button.
    public let contextSource: IrisContextSource?

    /// Convenience for the enclosing course's id.
    public var courseId: Int {
        coursePath.id
    }

    public init(sessionId: Int, defaultInput: String = "", contextSource: IrisContextSource? = nil, coursePath: CoursePath) {
        self.sessionId = sessionId
        self.defaultInput = defaultInput
        self.contextSource = contextSource
        self.coursePath = coursePath
    }
}

public struct IrisStartChatPath: Hashable {
    public let inputText: String
    public let coursePath: CoursePath

    /// Convenience for the enclosing course's id.
    public var courseId: Int {
        coursePath.id
    }

    public init(inputText: String, coursePath: CoursePath) {
        self.inputText = inputText
        self.coursePath = coursePath
    }
}
