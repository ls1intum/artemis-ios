//
//  SendMessageExercisePicker.swift
//
//
//  Created by Nityananda Zbil on 29.10.23.
//

import SharedModels
import SwiftUI

struct SendMessageExercisePicker: View {

    @Environment(\.dismiss) var dismiss

    @Binding var text: String

    let course: Course

    var body: some View {
        if let exercises = course.exercises, !exercises.isEmpty {
            List(exercises) { exercise in
                if let title = exercise.baseExercise.title {
                    Button(title) {
                        appendMarkdown(for: exercise)
                        dismiss()
                    }
                }
            }
        } else {
            ContentUnavailableView(R.string.localizable.exercisesUnavailable(), systemImage: "magnifyingglass")
        }
    }
}

private extension SendMessageExercisePicker {
    func appendMarkdown(for exercise: Exercise) {
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

        text.append("[\(type)]\(title)(/courses/\(course.id)/exercises/\(exercise.id))[/\(type)]")
    }
}
