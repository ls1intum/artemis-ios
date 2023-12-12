//
//  ModelingExerciseSubmissionServiceImpl.swift
//  
//
//  Created by Alexander Görtzen on 21.11.23.
//

import APIClient
import SharedModels

class ModelingExerciseSubmissionServiceImpl: ExerciseSubmissionService {
    let client = APIClient()

    struct StartParticipationRequest: APIRequest {
        typealias Response = Participation

        let exerciseId: Int

        var method: HTTPMethod {
            .post
        }

        var resourceName: String {
            "api/exercises/\(exerciseId)/participations"
        }
    }

    func startParticipation(exerciseId: Int) async throws -> Participation {
        try await client.sendRequest(StartParticipationRequest(exerciseId: exerciseId)).get().0
    }

    struct GetLatestSubmissionRequest: APIRequest {
        typealias Response = Submission

        let participationId: Int

        var method: HTTPMethod {
            .get
        }

        var resourceName: String {
            "api/participations/\(participationId)/latest-modeling-submission"
        }
    }

    func getLatestSubmission(participationId: Int) async throws -> Submission {
        try await client.sendRequest(GetLatestSubmissionRequest(participationId: participationId)).get().0
    }

    struct CreateSubmissionRequest: APIRequest {
        typealias Response = Submission

        let exerciseId: Int
        let modelingDTO: ModelingSubmission

        var method: HTTPMethod {
            .post
        }

        var body: Encodable? {
            modelingDTO
        }

        var resourceName: String {
            "api/exercises/\(exerciseId)/modeling-submissions"
        }
    }

    func createSubmission(exerciseId: Int, submission: BaseSubmission) async throws {
        guard let modelingDTO = submission as? ModelingSubmission else {
            return
        }
        _ = try await client.sendRequest(CreateSubmissionRequest(exerciseId: exerciseId, modelingDTO: modelingDTO)).get()
    }

    struct PutSubmissionRequest: APIRequest {
        typealias Response = Submission

        let exerciseId: Int
        let modelingDTO: ModelingSubmission

        var method: HTTPMethod {
            .put
        }

        var body: Encodable? {
            modelingDTO
        }

        var resourceName: String {
            "api/exercises/\(exerciseId)/modeling-submissions"
        }
    }

    func updateSubmission(exerciseId: Int, submission: BaseSubmission) async throws {
        guard let modelingDTO = submission as? ModelingSubmission else {
            return
        }
       _ = try await client.sendRequest(PutSubmissionRequest(exerciseId: exerciseId, modelingDTO: modelingDTO)).get()
    }
}
