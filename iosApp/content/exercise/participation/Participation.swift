import Foundation

protocol Participation: Decodable {
    var id: Int? { get }
    var initializationState: InitializationState? { get }
    var initializationDate: Date? { get }
    var individualDueDate: Date? { get }
    var results: [Result]? { get }
    var exercise: Exercise? { get }
    var submissions: [Submission]? { get }
}

enum InitializationState: String, Decodable {
    case UNINITIALIZED
    case REPO_COPIED
    case REPO_CONFIGURED
    case BUILD_PLAN_COPIED
    case BUILD_PLAN_CONFIGURED

    /**
    * The participation is set up for submissions from the student
    */
    case INITIALIZED

    /**
    * Text- / Modelling: At least one submission is done. Quiz: No further submissions should be possible
    */
    case FINISHED
    case INACTIVE
}

extension Participation {
    /**
     * Check if a given participation is in due time of the given exercise based on its submission at index position 0.
     * Before the method is called, it must be ensured that the submission at index position 0 is suitable to check if
     * the participation is in due time of the exercise.
     * From: https://github.com/ls1intum/Artemis/blob/310aa64d55c1347b4c2cf6367be551ce1d8f9a4a/src/main/webapp/app/exercises/shared/participation/participation.utils.ts#L87
     */
    func isInDueTime(associatedExercise: Exercise?) -> Bool {
        // If the exercise has no dueDate set, every submission is in time.
        if (associatedExercise?.dueDate == nil) {
            return true
        }

        // If the participation has no submission, it cannot be in due time.
        if ((submissions ?? []).isEmpty) {
            return false
        }

        // If the submissionDate is before the dueDate of the exercise, the submission is in time.
        let submission = submissions!.first!
        let submissionDate = submission.submissionDate
        if (submissionDate != nil) {
            let dueDate = associatedExercise?.getDueDate(participation: self)
            if dueDate == nil {
                return true
            }

            return submissionDate! < dueDate!
        }

        // If the submission has no submissionDate set, the submission cannot be in time.
        return false
    }
}