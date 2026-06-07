//
//  IrisContextSelectionViewModel.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 06.06.26.
//

import Common
import Foundation
import SharedModels
import SharedServices
import SwiftUI

/// Backs ``IrisContextSelectionView``. Loads the course once and exposes its
/// lectures and (text/programming) exercises filtered by the search text. The
/// chosen ``SessionContext`` is built on demand and handed straight to the chat
/// view model — this catalog holds no selection state of its own.
@MainActor
@Observable
final class IrisContextSelectionViewModel {
    private let courseId: Int
    private let courseService: CourseService

    var courseState: DataState<CourseForDashboardDTO> = .loading
    var searchText = ""

    init(courseId: Int,
         courseService: CourseService = CourseServiceFactory.shared) {
        self.courseId = courseId
        self.courseService = courseService
    }

    /// Fetches the course once and caches it, so reopening the sheet reuses the
    /// already-loaded lectures/exercises instead of refetching.
    func loadCourseIfNeeded() async {
        if case .done = courseState { return }
        courseState = await courseService.getCourse(courseId: courseId)
    }

    private var course: Course? {
        courseState.value?.course
    }

    /// Lectures of the course, filtered by the search text.
    var lectures: [Lecture] {
        (course?.lectures ?? []).filter { matches($0.title) }
    }

    /// Iris only supports text and programming exercises as a context (mirrors
    /// the web app's `EXERCISE_TYPE_TO_CHAT_MODE`), so other types are not listed.
    var exercises: [Exercise] {
        (course?.exercises ?? [])
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
