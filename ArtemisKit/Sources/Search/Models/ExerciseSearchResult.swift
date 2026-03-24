//
//  ExerciseSearchResult.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 22.03.26.
//

import Foundation
import Navigation

struct ExerciseSearchResult: SearchResultDetails {
    let courseId: Int?
    let courseName: String?

    let dueDate: Date?
    let releaseDate: Date?
    let points: Int?
    let difficulty: String?

    func navigateToDetail(with controller: NavigationController, result: SearchResultDTO) async {
        guard let courseId,
              let exerciseId = Int(result.id ?? "") else { return }
        await controller.goToExercise(courseId: courseId, exerciseId: exerciseId)
    }
}
