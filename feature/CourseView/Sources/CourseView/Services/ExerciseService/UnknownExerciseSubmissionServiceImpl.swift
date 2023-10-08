import Foundation
import SharedModels
import Common

class UnknownExerciseSubmissionServiceImpl: ExerciseSubmissionService {
    typealias SubmissionType = UnknownSubmission

    func getLatestSubmission(participationId: Int) async throws -> Submission {
        throw UserFacingError.init(title: "Not supported")
    }
}
