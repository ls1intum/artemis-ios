//
//  EditTextExerciseViewModel.swift
//
//
//  Created by Nityananda Zbil on 14.06.24.
//

import Common
import Foundation
import SharedModels

@Observable
final class EditTextExerciseViewModel {
    let exercise: Exercise
    let participationId: Int

    var problem: URLRequest

    var submission: BaseSubmission?
    var result: Result?

    var text: String = ""
    var isSubmitted = false

    var isProblemPresented = false
    var isSubmissionAlertPresented = false
    var isSubmissionSuccessful = false

    // MARK: Web view

    var isWebViewLoading = true

    init(exercise: Exercise, participationId: Int, problem: URLRequest) {
        self.exercise = exercise
        self.participationId = participationId
        self.problem = problem
    }

    func fetchSubmission() async {
    }

    func submit() async throws {
    }
}
