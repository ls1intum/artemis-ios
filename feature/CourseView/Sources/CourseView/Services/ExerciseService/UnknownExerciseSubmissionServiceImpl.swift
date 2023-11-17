import Foundation
import SharedModels
import Common

class UnknownExerciseSubmissionServiceImpl: ExerciseSubmissionService {
    typealias SubmissionType = UnknownSubmission

    func startParticipation(exerciseId: Int) async throws -> Participation {
        throw UserFacingError.init(title: "Not supported")
    }

    func getLatestSubmission(participationId: Int) async throws -> Submission {
        throw UserFacingError.init(title: "Not supported")
    }

    func postNewSubmission(exerciseId: Int, data: BaseSubmission) async throws {
        throw UserFacingError.init(title: "Not supported")
    }

    func putSubmission(exerciseId: Int, data: BaseSubmission) async throws {
        throw UserFacingError.init(title: "Not supported")
    }
}
