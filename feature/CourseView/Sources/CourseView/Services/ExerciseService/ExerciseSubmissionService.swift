import Foundation
import Common
import SharedModels
import ApollonShared

protocol ExerciseSubmissionService {
    func startParticipation(exerciseId: Int) async throws -> Participation
    func getLatestSubmission(participationId: Int) async throws -> Submission
    func postNewSubmission(exerciseId: Int, data: BaseSubmission) async throws
    func putSubmission(exerciseId: Int, data: BaseSubmission) async throws
}

enum ExerciseSubmissionServiceFactory {
    static func service(for exercise: Exercise) -> any ExerciseSubmissionService {
        switch exercise {
        case .modeling:
            return ModelingExerciseSubmissionServiceImpl()
        default:
            return UnknownExerciseSubmissionServiceImpl()
        }
    }
}
