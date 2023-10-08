import Foundation
import Common
import SharedModels

protocol ExerciseSubmissionService {
    func getLatestSubmission(participationId: Int) async throws -> Submission
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
