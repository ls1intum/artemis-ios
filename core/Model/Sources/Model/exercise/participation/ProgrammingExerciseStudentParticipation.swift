import Foundation

public class ProgrammingExerciseStudentParticipation: StudentParticipation {

    public static var type: String {
        "programming"
    }

    public var student: User? = nil
    public var team: Team? = nil
    public var participantIdentifier: String? = nil
    public var testRun: Bool? = nil
    public var id: Int? = nil
    public var initializationState: InitializationState? = nil
    public var initializationDate: Date? = nil
    public var individualDueDate: Date? = nil
    public var results: [Result]? = nil
    public var exercise: Exercise? = nil
    public var submissions: [Submission]? = nil
    public var repositoryUrl: String? = nil
    public var buildPlanId: String? = nil
}
