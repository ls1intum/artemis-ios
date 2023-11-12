import Foundation
import UserStore
import Common
import SharedModels
import APIClient
import ApollonShared

class ModelingExerciseSubmissionServiceImpl: ExerciseSubmissionService {
    let client = APIClient()

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
        let modelingDTO: UMLModel

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
    
    func postNewSubmission(exerciseId: Int, modelingDTO: UMLModel) async throws {
        _ = try await client.sendRequest(PostNewModelingSubmissionRequest(exerciseId: exerciseId, modelingDTO: modelingDTO)).get()
    }

    // Put modeling submission
    struct PutModelingSubmissionRequest: APIRequest {
        typealias Response = Submission

        let exerciseId: Int
        let modelingDTO: UMLModel

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

    func putSubmission(exerciseId: Int, modelingDTO: UMLModel) async throws {
       _ = try await client.sendRequest(PutModelingSubmissionRequest(exerciseId: exerciseId, modelingDTO: modelingDTO)).get()
    }

}
