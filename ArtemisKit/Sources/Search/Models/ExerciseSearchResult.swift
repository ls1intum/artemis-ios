//
//  ExerciseSearchResult.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 22.03.26.
//

import Foundation
import Navigation
import SwiftUI

struct ExerciseSearchResult: SearchResultDetails {
    let courseId: Int?
    let courseName: String?

    let dueDate: Date?
    let releaseDate: Date?
    let points: Int?
    let difficulty: String?

    var displayInfo: [Text] {
        var info = [Text]()

        if let dueDate {
            let image = Image(systemName: "calendar")
            info.append(Text("\(image) Due: \(dueDate.mediumDateShortTime)"))
        }

        if let points {
            let image = Image(systemName: "trophy")
            info.append(Text("\(image) \(points) Points"))
        }

        return info
    }

    func navigateToDetail(with controller: NavigationController, result: SearchResultDTO) async {
        guard let courseId,
              let exerciseId = Int(result.id ?? "") else { return }
        await controller.goToExercise(courseId: courseId, exerciseId: exerciseId)
    }
}
