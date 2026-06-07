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

/// Backs ``IrisContextSelectionView``. Loads the course once, exposes its
/// lectures and (text/programming) exercises filtered by the search text, and
/// holds the tentative selection until the user taps "Set".
@MainActor
@Observable
final class IrisContextSelectionViewModel {
    private let courseId: Int
    private let courseService: CourseService

    var courseState: DataState<CourseForDashboardDTO> = .loading
    var searchText = ""

    /// The tentative pick inside the sheet. Only pushed up to the chat view
    /// model when the user taps "Set"; dismissing the sheet discards it.
    var selection: SessionContext?

    init(courseId: Int,
         initialSelection: SessionContext? = nil,
         courseService: CourseService = CourseServiceFactory.shared) {
        self.courseId = courseId
        self.selection = initialSelection
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

    func select(lecture: Lecture) {
        selection = SessionContext(mode: .lecture,
                                   entityId: lecture.id,
                                   entityName: lecture.title)
    }

    func select(exercise: Exercise) {
        selection = SessionContext(mode: mode(for: exercise),
                                   entityId: exercise.id,
                                   entityName: exercise.baseExercise.title)
    }

    func isSelected(lecture: Lecture) -> Bool {
        selection?.mode == .lecture && selection?.entityId == lecture.id
    }

    func isSelected(exercise: Exercise) -> Bool {
        selection?.mode == mode(for: exercise) && selection?.entityId == exercise.id
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
