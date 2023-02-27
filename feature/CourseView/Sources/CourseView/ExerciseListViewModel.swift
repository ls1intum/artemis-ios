//
//  File.swift
//  
//
//  Created by Sven Andabaka on 27.02.23.
//

import Foundation
import SharedModels
import SwiftUI

@MainActor
class ExerciseListViewModel: ObservableObject {

    @Published var weeklyExercises: [WeeklyExercise] = []

    @Published var course: Course {
        didSet {
            setupExercises()
        }
    }

    init(course: Course) {
        self._course = Published(initialValue: course)
    }

    private func setupExercises() {
        var groupedDates = [WeeklyExerciseId: [Exercise]]()

        course.exercises?.forEach { exercise in
            var week: Int?
            var year: Int?
            if let dueDate = exercise.baseExercise.dueDate {
                week = Calendar.current.component(.weekOfYear, from: dueDate)
                year = Calendar.current.component(.year, from: dueDate)
            }

            let weeklyExerciseId = WeeklyExerciseId(week: week, year: year)

            if groupedDates[weeklyExerciseId] == nil {
                groupedDates[weeklyExerciseId] = [exercise]
            } else {
                groupedDates[weeklyExerciseId]?.append(exercise)
            }
        }

        weeklyExercises = groupedDates.map { week in
            WeeklyExercise(id: week.key, exercises: week.value)
        }
    }
}

struct WeeklyExerciseId: Identifiable, Hashable {
    let week: Int?
    let year: Int?

    var id: String {
        guard let week = week,
              let year = year else {
            return "undefined"
        }
        return "\(week)/\(year)"
    }

    var description: String {
        // TODO: adjust
        "22.3 - 29.3"
    }
}

struct WeeklyExercise: Identifiable {
    let id: WeeklyExerciseId
    var exercises: [Exercise]
}
