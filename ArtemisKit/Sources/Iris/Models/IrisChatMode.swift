//
//  IrisChatMode.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 05.06.26.
//

import SharedModels

/// Identifies the Iris chat mode.
/// Mirrors the server `IrisChatMode` enum.
enum IrisChatMode: String, ConstantsEnum {
    case textExercise = "TEXT_EXERCISE_CHAT"
    case programmingExercise = "PROGRAMMING_EXERCISE_CHAT"
    case course = "COURSE_CHAT"
    case lecture = "LECTURE_CHAT"
    case tutorSuggestion = "TUTOR_SUGGESTION"
    case unknown
}
