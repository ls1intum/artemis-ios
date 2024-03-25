//
//  NavigationPathValues.swift
//
//
//  Created by Nityananda Zbil on 26.02.24.
//

import SharedModels

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
