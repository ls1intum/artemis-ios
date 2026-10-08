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
    let points: Double?
    let difficulty: String?

    var displayInfo: [Text] {
        var info = [Text]()

        if let dueDate {
            let image = Image(systemName: "calendar")
            info.append(Text("\(image)\u{00A0}Due:\u{00A0}\(dueDate.mediumDateShortTime)"))
        }

        if let points {
            let image = Image(systemName: "trophy")
            info.append(Text("\(image)\u{00A0}\(points.clean)\u{00A0}Points"))
        }

        return info
    }

    func navigateToDetail(with controller: NavigationController, result: SearchResultDTO) async {
        guard let courseId,
              let exerciseId = Int(result.id ?? "") else { return }
        await controller.goToExercise(courseId: courseId, exerciseId: exerciseId)
    }
}

private extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}
