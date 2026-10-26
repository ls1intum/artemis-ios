//
//  NavigationPathValues.swift
//
//
//  Created by Nityananda Zbil on 26.02.24.
//

import Foundation
import SharedModels

public struct CoursePath: Hashable, Identifiable {
    public let id: Int
    public let course: CourseForOverviewDTO?
    public let tabs: CourseAvailableTabsDTO?

    public init(id: Int) {
        self.id = id
        self.course = nil
        self.tabs = nil
    }

    public init(course: CourseForOverviewDTO, tabs: CourseAvailableTabsDTO) {
        self.id = course.id
        self.course = course
        self.tabs = tabs
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

/// An explicit reference is kept separate from locally remembered reading position.
public struct LectureMediaTarget: Hashable {
    public let unitId: Int64?
    public let attachmentId: Int?
    public let page: Int?
    public let attachmentFilename: String?
    public let slideId: Int?
    public let originalSlideNumber: Int?
    public let visibleSlideNumbers: [Int]?

    public init(unitId: Int64? = nil, attachmentId: Int? = nil, page: Int? = nil, attachmentFilename: String? = nil, slideId: Int? = nil, originalSlideNumber: Int? = nil, visibleSlideNumbers: [Int]? = nil) {
        self.unitId = unitId
        self.attachmentId = attachmentId
        self.page = page
        self.attachmentFilename = attachmentFilename
        self.slideId = slideId
        self.originalSlideNumber = originalSlideNumber
        self.visibleSlideNumbers = visibleSlideNumbers
    }

    public func resolve(in units: [LectureUnit]) -> LectureUnit? {
        units.first(where: { unit in
            if let unitId { return unit.id == unitId }
            if let attachmentId, case .attachmentVideo(let attachment) = unit {
                return attachment.attachment?.id == attachmentId
            }
            if let attachmentFilename, case .attachmentVideo(let attachment) = unit,
               let link = attachment.attachment?.link, let url = URL(string: link) {
                return url.lastPathComponent == attachmentFilename
            }
            return false
        })
    }
}

public struct LecturePath: Hashable {
    public let id: Int
    public let lecture: Lecture?
    public let coursePath: CoursePath
    public let target: LectureMediaTarget?
    /// Each explicit open gets fresh consumption state, even for the same slide.
    public let referenceRequestID: UUID?
    public var presentationIdentity: AnyHashable { referenceRequestID.map(AnyHashable.init) ?? AnyHashable(id) }

    public init(id: Int, coursePath: CoursePath, target: LectureMediaTarget? = nil) {
        self.id = id
        self.lecture = nil
        self.coursePath = coursePath
        self.target = target
        self.referenceRequestID = target.map { _ in UUID() }
    }

    public init(lecture: Lecture, coursePath: CoursePath, target: LectureMediaTarget? = nil) {
        self.id = lecture.id
        self.lecture = lecture
        self.coursePath = coursePath
        self.target = target
        self.referenceRequestID = target.map { _ in UUID() }
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
