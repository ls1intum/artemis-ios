//
//  File.swift
//  
//
//  Created by Sven Andabaka on 09.04.23.
//

import Foundation

struct ExerciseHandler: Deeplink {

    let courseId: Int
    let exerciseId: Int

    static func build(from url: URL) -> ExerciseHandler? {
        guard let indexOfCourseId = url.pathComponents.firstIndex(where: { $0 == "courses" }),
              url.pathComponents.count > indexOfCourseId + 1,
              let courseId = Int(url.pathComponents[indexOfCourseId + 1]),
              let indexOfExerciseId = url.pathComponents.firstIndex(where: { $0 == "exercises" }),
              url.pathComponents.count > indexOfExerciseId + 1,
              let exerciseId = Int(url.pathComponents[indexOfExerciseId + 1]),
              let urlComponent = URLComponents(string: url.absoluteString),
              !(urlComponent.queryItems?.contains(where: { $0.name == "postId" }) ?? false) else { return nil }

        return ExerciseHandler(courseId: courseId, exerciseId: exerciseId)
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            await navigationController.goToExercise(courseId: courseId, exerciseId: exerciseId)
        }
    }
}
