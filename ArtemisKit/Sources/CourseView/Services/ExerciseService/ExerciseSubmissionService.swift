//
//  ExerciseSubmissionService.swift
//  
//
//  Created by Alexander Görtzen on 21.11.23.
//

import SharedModels

protocol ExerciseSubmissionService {

    func startParticipation(exerciseId: Int) async throws -> Participation

    func getLatestSubmission(participationId: Int) async throws -> Submission

    func createSubmission(exerciseId: Int, submission: BaseSubmission) async throws

    func updateSubmission(exerciseId: Int, submission: BaseSubmission) async throws
}

// Native submission services currently cover modeling and text; other types use the fallback.
enum ExerciseSubmissionServiceFactory {
    static func service(for exercise: Exercise) -> ExerciseSubmissionService {
        switch exercise {
        case .modeling:
            return ModelingExerciseSubmissionServiceImpl()
        case .text:
            return TextExerciseSubmissionServiceImpl()
        default:
            return UnknownExerciseSubmissionServiceImpl()
        }
    }
}
