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

extension Exercise {
    /// The Iris chat mode for this exercise, or `nil` for types Iris has no chat for.
    /// Mirrors the web app's `EXERCISE_TYPE_TO_CHAT_MODE`.
    var irisChatMode: IrisChatMode? {
        switch self {
        case .programming: .programmingExercise
        case .text: .textExercise
        default: nil
        }
    }
}

extension IrisChatMode {
    var icon: String {
        switch self {
        case .programmingExercise:
            "keyboard"
        case .textExercise:
            "character"
        case .course:
            "graduationcap"
        case .lecture:
            "inset.filled.rectangle.and.person.filled"
        case .tutorSuggestion, .unknown:
            "questionmark"
        }
    }
}
