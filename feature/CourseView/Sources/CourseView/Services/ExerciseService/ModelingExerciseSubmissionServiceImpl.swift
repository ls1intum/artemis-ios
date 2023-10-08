import Foundation
import UserStore
import Common
import SharedModels
import APIClient

class ModelingExerciseSubmissionServiceImpl: ExerciseSubmissionService {
    let client = APIClient()

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
}
