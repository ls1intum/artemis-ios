//
//  PushNotification.swift
//  Artemis
//
//  Created by Sven Andabaka on 19.02.23.
//  Copyright © 2023 orgName. All rights reserved.
//

import Foundation

struct PushNotification: Codable {
    var notificationPlaceholders: [String] = []
    var target: String
    var type: PushNotificationType

    var title: String {
        return "TODO"
    }
    var body: String {
        return "TODO Body"
    }
}

enum PushNotificationType: String, RawRepresentable, Codable {
    case exerciseSubmissionAssessed = "EXERCISE_SUBMISSION_ASSESSED"
    case attachmentChange = "ATTACHMENT_CHANGE"
    case exerciseReleased = "EXERCISE_RELEASED"
    case exercisePractice = "EXERCISE_PRACTICE"
    case quizExerciseStarted = "QUIZ_EXERCISE_STARTED"
    case newReplyForLecturePost = "NEW_REPLY_FOR_LECTURE_POST"
    case newReplyForCoursePost = "NEW_REPLY_FOR_COURSE_POST"
    case newExercisePost = "NEW_EXERCISE_POST"
    case newLecturePost = "NEW_LECTURE_POST"
    case newCoursePost = "NEW_COURSE_POST"
    case newAnnouncementPost = "NEW_ANNOUNCEMENT_POST"
    case fileSubmissionSuccessful = "FILE_SUBMISSION_SUCCESSFUL"
    case duplicateTestCase = "DUPLICATE_TEST_CASE"
    case newPlagiarismCaseStudent = "NEW_PLAGIARISM_CASE_STUDENT"
    case plagiarismCaseVerdictStudent = "PLAGIARISM_CASE_VERDICT_STUDENT"
    // TODO: maybe following needed as well
//    TUTORIAL_GROUP_REGISTRATION_STUDENT, TUTORIAL_GROUP_REGISTRATION_TUTOR, TUTORIAL_GROUP_MULTIPLE_REGISTRATION_TUTOR, TUTORIAL_GROUP_DEREGISTRATION_STUDENT,
//    TUTORIAL_GROUP_DEREGISTRATION_TUTOR, TUTORIAL_GROUP_DELETED, TUTORIAL_GROUP_UPDATED, TUTORIAL_GROUP_ASSIGNED, TUTORIAL_GROUP_UNASSIGNED,
}
