//
//  SendMessageExercisePicker.swift
//
//
//  Created by Nityananda Zbil on 29.10.23.
//

import SharedModels
import SwiftUI

struct SendMessageExercisePicker: View {

    let delegate: SendMessageMentionContentDelegate

    let course: Course

    var body: some View {
        Group {
            if let exercises = course.exercises, !exercises.isEmpty {
                List(exercises) { exercise in
                    if let title = exercise.baseExercise.title {
                        Button(title) {
                            selectMention(for: exercise)
                        }
                    }
                }
                .listStyle(.plain)
            } else {
                ContentUnavailableView(R.string.localizable.exercisesUnavailable(), systemImage: "magnifyingglass")
            }
        }
        .navigationTitle("Exercises")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension SendMessageExercisePicker {
    func selectMention(for exercise: Exercise) {
        let type: String?
        switch exercise {
        case .fileUpload:
            type = "file-upload"
        case .modeling:
            type = "modeling"
        case .programming:
            type = "programming"
        case .quiz:
            type = "quiz"
        case .text:
            type = "text"
        case .unknown:
            type = nil
        }

        guard let type, let title = exercise.baseExercise.title else {
            return
        }

        delegate.pickerDidSelect("[\(type)]\(title)(/courses/\(course.id)/exercises/\(exercise.id))[/\(type)]")
    }
}
