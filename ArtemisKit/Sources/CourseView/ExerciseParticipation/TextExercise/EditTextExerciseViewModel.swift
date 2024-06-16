//
//  EditTextExerciseViewModel.swift
//
//
//  Created by Nityananda Zbil on 14.06.24.
//

import Common
import Foundation
import SharedModels
import SharedServices

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
        guard submission == nil else {
            return
        }

        let exerciseService = ExerciseServiceFactory.shared

        let data = await exerciseService.getExercise(exerciseId: exercise.id)
        guard let exercise = data.value,
              case let .text(textExercise) = exercise,
              let studentParticipations = textExercise.studentParticipations,
              let studentParticipation = studentParticipations.first,
              case let .student(student) = studentParticipation,
              let submissions = student.submissions,
              let submission = submissions.first,
              case let .text(textSubmission) = submission
        else {
            log.error(String(describing: "Submission unavailable"))
            return
        }

        self.submission = textSubmission
        if let result = textSubmission.results?.first, let result {
            self.result = result
        }
        if let text = textSubmission.text {
            self.text = text
        }
    }

    func submit() async throws {
    }
}
