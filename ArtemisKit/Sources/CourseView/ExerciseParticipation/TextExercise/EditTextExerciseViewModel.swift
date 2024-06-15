//
//  EditTextExerciseViewModel.swift
//
//
//  Created by Nityananda Zbil on 14.06.24.
//

import Foundation
import SharedModels

@Observable
final class EditTextExerciseViewModel {
    let exercise: Exercise
    var problem: URLRequest

    var text: String = ""
    var isSubmitted = false

    var isProblemStatementPresented = false

    // MARK: Web view

    var isWebViewLoading = true

    private let exerciseSubmissionService = TextExerciseSubmissionService()

    init(exercise: Exercise, problem: URLRequest) {
        self.exercise = exercise
        self.problem = problem
    }
}
