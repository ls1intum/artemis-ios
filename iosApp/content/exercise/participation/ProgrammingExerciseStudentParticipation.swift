import Foundation

class ProgrammingExerciseStudentParticipation: StudentParticipation {

    public static var type: String {
        "programming"
    }

    var student: User? = nil
    var team: Team? = nil
    var participantIdentifier: String? = nil
    var testRun: Bool? = nil
    var id: Int? = nil
    var initializationState: InitializationState? = nil
    var initializationDate: Date? = nil
    var individualDueDate: Date? = nil
    var results: [Result]? = nil
    var exercise: Exercise? = nil
    var submissions: [Submission]? = nil
    var repositoryUrl: String? = nil
    var buildPlanId: String? = nil
}
