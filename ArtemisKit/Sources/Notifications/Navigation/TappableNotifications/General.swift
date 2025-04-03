//
//  General.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 31.03.25.
//

import Navigation
import PushNotifications

extension ExerciseAssessedNotification: TappableNotification {
    @MainActor
    func handleTap(with navController: NavigationController) async {
        // CoursePath always exists in context of CourseNotifications
        guard let coursePath = navController.selectedCourse else { return }
        navController.setTab(identifier: .exercise)
        guard let exerciseId else { return }
        navController.selectedPath = ExercisePath(id: exerciseId, coursePath: coursePath)
    }
}

extension ExerciseOpenForPracticeNotification: TappableNotification {
    @MainActor
    func handleTap(with navController: NavigationController) async {
        // CoursePath always exists in context of CourseNotifications
        guard let coursePath = navController.selectedCourse else { return }
        navController.setTab(identifier: .exercise)
        guard let exerciseId else { return }
        navController.selectedPath = ExercisePath(id: exerciseId, coursePath: coursePath)
    }
}

extension ExerciseUpdatedNotification: TappableNotification {
    @MainActor
    func handleTap(with navController: NavigationController) async {
        // CoursePath always exists in context of CourseNotifications
        guard let coursePath = navController.selectedCourse else { return }
        navController.setTab(identifier: .exercise)
        guard let exerciseId else { return }
        navController.selectedPath = ExercisePath(id: exerciseId, coursePath: coursePath)
    }
}

extension NewExerciseNotification: TappableNotification {
    @MainActor
    func handleTap(with navController: NavigationController) async {
        // CoursePath always exists in context of CourseNotifications
        guard let coursePath = navController.selectedCourse else { return }
        navController.setTab(identifier: .exercise)
        guard let exerciseId else { return }
        navController.selectedPath = ExercisePath(id: exerciseId, coursePath: coursePath)
    }
}

extension NewManualFeedbackRequestNotification: TappableNotification {
    @MainActor
    func handleTap(with navController: NavigationController) async {
        // CoursePath always exists in context of CourseNotifications
        guard let coursePath = navController.selectedCourse else { return }
        navController.setTab(identifier: .exercise)
        guard let exerciseId else { return }
        navController.selectedPath = ExercisePath(id: exerciseId, coursePath: coursePath)
    }
}

extension AttachmentChangedNotification: TappableNotification {
    @MainActor
    func handleTap(with navController: NavigationController) async {
        // CoursePath always exists in context of CourseNotifications
        guard let coursePath = navController.selectedCourse else { return }
        if let exerciseId {
            navController.setTab(identifier: .exercise)
            navController.selectedPath = ExercisePath(id: exerciseId, coursePath: coursePath)
        }
        if let lectureId {
            navController.setTab(identifier: .lecture)
            navController.selectedPath = LecturePath(id: lectureId, coursePath: coursePath)
        }
    }
}
