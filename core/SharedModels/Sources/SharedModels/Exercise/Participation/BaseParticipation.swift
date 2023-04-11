import Foundation

public protocol BaseParticipation: Codable {
    static var type: String { get }

    var id: Int { get }
    var initializationState: InitializationState? { get }
    var initializationDate: Date? { get }
    var individualDueDate: Date? { get }
    var results: [Result]? { get }
    var exercise: Exercise? { get }
    var submissions: [Submission]? { get }
}

public enum Participation: Identifiable, Codable {
    fileprivate enum CodingKeys: String, CodingKey {
        case type
    }

    case student(participation: StudentParticipationImpl)
    case programmingExerciseStudent(participation: ProgrammingExerciseStudentParticipation)
    case unknown(participation: UnknownParticipation)

    public var baseParticipation: BaseParticipation {
        switch self {
        case .student(let participation): return participation
        case .programmingExerciseStudent(let participation): return participation
        case .unknown(let participation): return participation
        }
    }

    public var id: Int {
        baseParticipation.id
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: CodingKeys.type)
        switch type {
        case StudentParticipationImpl.type: self = .student(participation: try StudentParticipationImpl(from: decoder))
        case ProgrammingExerciseStudentParticipation.type: self = .programmingExerciseStudent(participation: try ProgrammingExerciseStudentParticipation(from: decoder))
        default: self = .unknown(participation: try UnknownParticipation(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .student(let participation):
            try participation.encode(to: encoder)
        case .programmingExerciseStudent(let participation):
            try participation.encode(to: encoder)
        case .unknown(let participation):
            try participation.encode(to: encoder)
        }
    }
}

public enum InitializationState: String, Codable {
    case uninitalized = "UNINITIALIZED"
    case repoCopied = "REPO_COPIED"
    case repoConfigured = "REPO_CONFIGURED"
    case buildPlanCopied = "BUILD_PLAN_COPIED"
    case buildPlanConfigured = "BUILD_PLAN_CONFIGURED"

    /**
     * The participation is set up for submissions from the student
     */
    case initialized = "INITIALIZED"

    /**
     * Text- / Modelling: At least one submission is done. Quiz: No further submissions should be possible
     */
    case finished = "FINISHED"
    case inactive = "INACTIVE"
}

public extension BaseParticipation {
    /**
     * Check if a given participation is in due time of the given exercise based on its submission at index position 0.
     * Before the method is called, it must be ensured that the submission at index position 0 is suitable to check if
     * the participation is in due time of the exercise.
     * From: https://github.com/ls1intum/Artemis/blob/310aa64d55c1347b4c2cf6367be551ce1d8f9a4a/src/main/webapp/app/exercises/shared/participation/participation.utils.ts#L87
     */
    func isInDueTime(exercise: Exercise) -> Bool {
        // If the exercise has no dueDate set, every submission is in time.
        guard let dueDate = exercise.baseExercise.dueDate else {
            return true
        }

        // If the participation has no submission, it cannot be in due time.
        guard let submission = submissions?.first else {
            return false
        }

        // If the submissionDate is before the dueDate of the exercise, the submission is in time.
        if let submissionDate = submission.baseSubmission.submissionDate {
            return submissionDate < dueDate
        }

        // If the submission has no submissionDate set, the submission cannot be in time.
        return false
    }
}
