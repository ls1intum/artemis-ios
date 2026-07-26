//
//  IrisContextSelectionViewModel.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 06.06.26.
//

import SharedModels
import SwiftUI

/// Backs ``IrisContextSelectionView``. Exposes a course's lectures and
/// (text/programming) exercises filtered by the search text. The chosen
/// ``SessionContext`` is built on demand and handed straight to the chat view
/// model — this catalog holds no selection state of its own. The course itself
/// is loaded by ``CoursePathView`` and passed into the filtering methods.
@MainActor
@Observable
final class IrisContextSelectionViewModel {
    var searchText = ""

    /// Lectures of the course, filtered by the search text.
    func lectures(in course: Course) -> [Lecture] {
        (course.lectures ?? []).filter { matches($0.title) }
    }

    /// Iris only supports text and programming exercises as a context (mirrors
    /// the web app's `EXERCISE_TYPE_TO_CHAT_MODE`), so other types are not listed.
    func exercises(in course: Course) -> [Exercise] {
        (course.exercises ?? [])
            .filter { $0.irisChatMode != nil }
            .filter { matches($0.baseExercise.title) }
    }

    func context(for lecture: Lecture) -> SessionContext {
        SessionContext(lecture: lecture)
    }

    /// `nil` for an exercise type Iris has no chat mode for; callers only pass
    /// exercises already filtered by ``exercises(in:)``, so in practice never nil.
    func context(for exercise: Exercise) -> SessionContext? {
        exercise.irisChatMode.map {
            SessionContext(mode: $0, entityId: exercise.id, entityName: exercise.baseExercise.title)
        }
    }

    func isSelected(lecture: Lecture, current: SessionContext?) -> Bool {
        current?.mode == .lecture && current?.entityId == lecture.id
    }

    func isSelected(exercise: Exercise, current: SessionContext?) -> Bool {
        current?.mode == exercise.irisChatMode && current?.entityId == exercise.id
    }

    private func matches(_ title: String?) -> Bool {
        guard !searchText.isEmpty else { return true }
        return title?.localizedCaseInsensitiveContains(searchText) ?? false
    }
}
