//
//  ExerciseSubmissionService.swift
//  
//
//  Created by Alexander Görtzen on 21.11.23.
//

import Foundation
import Common
import SharedModels

protocol ExerciseSubmissionService {
    func initializeParticipation(exerciseId: Int) async throws -> Participation
    func getLatestSubmission(participationId: Int) async throws -> Submission
    func postNewSubmission(exerciseId: Int, data: BaseSubmission) async throws
    func putSubmission(exerciseId: Int, data: BaseSubmission) async throws
}

// TODO: Add ExerciseSubmission for all other exercise types
enum ExerciseSubmissionServiceFactory {
    static func service(for exercise: Exercise) -> ExerciseSubmissionService {
        switch exercise {
        case .modeling:
            return ModelingExerciseSubmissionServiceImpl()
        default:
            return UnknownExerciseSubmissionServiceImpl()
        }
    }
}
