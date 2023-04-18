//
//  File.swift
//  
//
//  Created by Sven Andabaka on 28.03.23.
//

import Foundation

public struct PushNotificationSetting: Codable {
    public let settingId: PushNotificationSettingId
    public let webapp: Bool
    public let email: Bool
    public var push: Bool = false
}

public enum PushNotificationSettingId: String, RawRepresentable, Codable {
    // Course-Wide Dicussion Notifications
    case newCoursePost = "notification.course-wide-discussion.new-course-post"
    case newReplyForCoursePost = "notification.course-wide-discussion.new-reply-for-course-post"
    case newAnnouncementPost = "notification.course-wide-discussion.new-announcement-post"

    // Exercise Notifications
    case exerciseReleased = "notification.exercise-notification.exercise-released"
    case exercisePractice = "notification.exercise-notification.exercise-open-for-practice"
    case exerciseSubmissionAssessed = "notification.exercise-notification.exercise-submission-assessed"
    case fileSubmissionSuccessful = "notification.exercise-notification.file-submission-successful"
    case newExercisePost = "notification.exercise-notification.new-exercise-post"
    case newReplyForExercisePost = "notification.exercise-notification.new-reply-for-exercise-post"

    // Lecture Notifications
    case attachmentChange = "notification.lecture-notification.attachment-changes"
    case newLecturePost = "notification.lecture-notification.new-lecture-post"
    case newReplyForLecturePost = "notification.lecture-notification.new-reply-for-lecture-post"

    // Tutorial Group Notifications
    case tutorialGroupRegistrationStudent = "notification.tutorial-group-notification.tutorial-group-registration"
    case tutorialGroupDeleteUpdateStudent = "notification.tutorial-group-notification.tutorial-group-delete-update"

    // Tutor Group Notifications
    case tutorialGroupRegistrationTutor = "notification.tutor-notification.tutorial-group-registration"
    case tutorialGroupAssignUnassignTutor = "notification.tutor-notification.tutorial-group-assign-unassign"

    case other

    public init(from decoder: Decoder) throws {
        self = try PushNotificationSettingId(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .other
    }
}
