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
            .filter(isSupported)
            .filter { matches($0.baseExercise.title) }
    }

    func context(for lecture: Lecture) -> SessionContext {
        SessionContext(mode: .lecture,
                       entityId: lecture.id,
                       entityName: lecture.title)
    }

    func context(for exercise: Exercise) -> SessionContext {
        SessionContext(mode: mode(for: exercise),
                       entityId: exercise.id,
                       entityName: exercise.baseExercise.title)
    }

    func isSelected(lecture: Lecture, current: SessionContext?) -> Bool {
        current?.mode == .lecture && current?.entityId == lecture.id
    }

    func isSelected(exercise: Exercise, current: SessionContext?) -> Bool {
        current?.mode == mode(for: exercise) && current?.entityId == exercise.id
    }

    private func matches(_ title: String?) -> Bool {
        guard !searchText.isEmpty else { return true }
        return title?.localizedCaseInsensitiveContains(searchText) ?? false
    }

    private func isSupported(_ exercise: Exercise) -> Bool {
        switch exercise {
        case .text, .programming:
            return true
        default:
            return false
        }
    }

    private func mode(for exercise: Exercise) -> IrisChatMode {
        switch exercise {
        case .programming:
            return .programmingExercise
        default:
            return .textExercise
        }
    }
}
