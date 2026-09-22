//
//  SendMessageExercisePicker.swift
//
//
//  Created by Nityananda Zbil on 29.10.23.
//

import SharedModels
import SwiftUI

struct SendMessageExercisePicker: View {
    @State private var viewModel: SendMessageExercisePickerViewModel

    var body: some View {
        Group {
            if !viewModel.exercises.isEmpty {
                List(viewModel.exercises) { exercise in
                    if let title = exercise.baseExercise.title {
                        Button(title) {
                            viewModel.select(exercise: exercise)
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

extension SendMessageExercisePicker {
    init(course: CourseForOverviewDTO, delegate: SendMessageMentionContentDelegate) {
        self.init(viewModel: SendMessageExercisePickerViewModel(course: course, delegate: delegate))
    }
}
