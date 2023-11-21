//
//  ModelingExerciseSubmissionServiceImpl.swift
//  
//
//  Created by Alexander Görtzen on 21.11.23.
//

import Foundation
import UserStore
import Common
import SharedModels
import APIClient

class ModelingExerciseSubmissionServiceImpl: ExerciseSubmissionService {
    let client = APIClient()

    // Initialize participation
    struct InitializeModelingParticipationRequest: APIRequest {
        typealias Response = Participation

        let exerciseId: Int

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            "api/exercises/\(exerciseId)/participations"
        }
    }

    func initializeParticipation(exerciseId: Int) async throws -> Participation {
        try await client.sendRequest(InitializeModelingParticipationRequest(exerciseId: exerciseId)).get().0
    }

    // Get latest modeling submission
    struct GetLatestModelingSubmissionRequest: APIRequest {
        typealias Response = Submission

        let participationId: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            "api/participations/\(participationId)/latest-modeling-submission"
        }
    }

    func getLatestSubmission(participationId: Int) async throws -> Submission {
        try await client.sendRequest(GetLatestModelingSubmissionRequest(participationId: participationId)).get().0
    }

    // Post new modeling submission
    struct PostNewModelingSubmissionRequest: APIRequest {
        typealias Response = Submission

        let exerciseId: Int
        let modelingDTO: ModelingSubmission

        var method: HTTPMethod {
            return .post
        }

        var body: Encodable? {
            modelingDTO
        }

        var resourceName: String {
            "api/exercises/\(exerciseId)/modeling-submissions"
        }
    }

    func postNewSubmission(exerciseId: Int, data: BaseSubmission) async throws {
        guard let modelingDTO = data as? ModelingSubmission else { return }
        _ = try await client.sendRequest(PostNewModelingSubmissionRequest(exerciseId: exerciseId, modelingDTO: modelingDTO)).get()
    }

    // Put modeling submission
    struct PutModelingSubmissionRequest: APIRequest {
        typealias Response = Submission

        let exerciseId: Int
        let modelingDTO: ModelingSubmission

        var method: HTTPMethod {
            return .put
        }

        var body: Encodable? {
            modelingDTO
        }

        var resourceName: String {
            "api/exercises/\(exerciseId)/modeling-submissions"
        }
    }

    func putSubmission(exerciseId: Int, data: BaseSubmission) async throws {
        guard let modelingDTO = data as? ModelingSubmission else { return }
       _ = try await client.sendRequest(PutModelingSubmissionRequest(exerciseId: exerciseId, modelingDTO: modelingDTO)).get()
    }
}
