import Foundation
import SharedModels
import Common

class UnknownExerciseSubmissionServiceImpl: ExerciseSubmissionService {
    typealias SubmissionType = UnknownSubmission
    
    private let defaultError = "Not supported"

    func getLatestSubmission(participationId: Int) async throws -> Submission {
        throw UserFacingError.init(title: defaultError)
    }
}
