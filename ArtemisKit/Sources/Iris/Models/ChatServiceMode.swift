//
//  ChatServiceMode.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import SharedModels

/// Identifies the Iris context a session belongs to.
/// Mirrors the `ChatServiceMode` TS enum in `iris-chat.service.ts`.
enum ChatServiceMode: String, ConstantsEnum {
    case textExercise = "TEXT_EXERCISE_CHAT"
    case programmingExercise = "PROGRAMMING_EXERCISE_CHAT"
    case course = "COURSE_CHAT"
    case lecture = "LECTURE_CHAT"
    case tutorSuggestion = "TUTOR_SUGGESTION"
    case unknown
}
