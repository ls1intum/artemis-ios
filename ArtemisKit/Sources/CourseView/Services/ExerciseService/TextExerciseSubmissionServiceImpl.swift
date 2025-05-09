//
//  TextExerciseSubmissionServiceImpl.swift
//
//
//  Created by Nityananda Zbil on 16.12.23.
//

import APIClient
import SharedModels

struct TextExerciseSubmissionServiceImpl: ExerciseSubmissionService {
    let client = APIClient()

    struct StartParticipationRequest: APIRequest {
        typealias Response = Participation

        let exerciseId: Int

        var method: HTTPMethod {
            .post
        }

        var resourceName: String {
            "api/exercise/exercises/\(exerciseId)/participations"
        }
    }

    func startParticipation(exerciseId: Int) async throws -> Participation {
        try await client.sendRequest(StartParticipationRequest(exerciseId: exerciseId)).get().0
    }

    enum GetLatestSubmissionError: Error {
        // Use ExerciseService.getExercise instead.
        case unavailable
    }

    func getLatestSubmission(participationId: Int) async throws -> Submission {
        throw GetLatestSubmissionError.unavailable
    }

    struct CreateSubmissionRequest: APIRequest {
        typealias Response = Submission

        let exerciseId: Int
        let submission: TextSubmission

        var method: HTTPMethod {
            .post
        }

        var body: Encodable? {
            submission
        }

        var resourceName: String {
            "api/text/exercises/\(exerciseId)/text-submissions"
        }
    }

    func createSubmission(exerciseId: Int, submission: BaseSubmission) async throws {
        guard let submission = submission as? TextSubmission else {
            return
        }
        _ = try await client.sendRequest(CreateSubmissionRequest(exerciseId: exerciseId, submission: submission)).get()
    }

    struct UpdateSubmissionRequest: APIRequest {
        typealias Response = Submission

        let exerciseId: Int
        let submission: TextSubmission

        var method: HTTPMethod {
            .put
        }

        var body: Encodable? {
            submission
        }

        var resourceName: String {
            "api/text/exercises/\(exerciseId)/text-submissions"
        }
    }

    func updateSubmission(exerciseId: Int, submission: BaseSubmission) async throws {
        guard let submission = submission as? TextSubmission else {
            return
        }
        _ = try await client.sendRequest(UpdateSubmissionRequest(exerciseId: exerciseId, submission: submission)).get()
    }
}
