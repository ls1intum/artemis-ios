//
//  UnknownExerciseSubmissionServiceImpl.swift
//  
//
//  Created by Alexander Görtzen on 21.11.23.
//

import Foundation
import SharedModels
import Common

class UnknownExerciseSubmissionServiceImpl: ExerciseSubmissionService {
    typealias SubmissionType = UnknownSubmission

    func startParticipation(exerciseId: Int) async throws -> Participation {
        throw UserFacingError(title: "Not supported")
    }

    func getLatestSubmission(participationId: Int) async throws -> Submission {
        throw UserFacingError(title: "Not supported")
    }

    func createSubmission(exerciseId: Int, submission: BaseSubmission) async throws {
        throw UserFacingError(title: "Not supported")
    }

    func updateSubmission(exerciseId: Int, submission: BaseSubmission) async throws {
        throw UserFacingError(title: "Not supported")
    }
}
