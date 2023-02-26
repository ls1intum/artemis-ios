import Foundation

public protocol BaseExercise: Decodable {
    associatedtype SelfType: BaseExercise

    static var type: String { get }

    var id: Int? { get }
    var title: String? { get }
    var shortName: String? { get }
    var maxPoints: Float? { get }
    var bonusPoints: Float? { get }
//    var releaseDate: Date? { get }
    var dueDate: Date? { get }
    var assessmentDueDate: Date? { get }
    var difficulty: Difficulty? { get }
    var mode: Mode { get }
    var categories: [Category]? { get }
    var visibleToStudents: Bool? { get }
    var teamMode: Bool? { get }
    var problemStatement: String? { get }
    var assessmentType: AssessmentType? { get }
    var allowComplaintsForAutomaticAssessments: Bool? { get }
    var allowManualFeedbackRequests: Bool? { get }
    var includedInOverallScore: IncludedInOverallScore { get }
    var exampleSolutionPublicationDate: Date? { get }
    var studentParticipations: [Participation]? { get }

    // -------
    var attachments: [Attachment]? { get }

    /**
     * Create a copy of this exercise with the participations field replaced.
     */
    func copyWithUpdatedParticipations(newParticipations: [Participation]) -> SelfType
}

public enum Exercise: Decodable {

    fileprivate enum Keys: String, CodingKey {
        case type
    }

    case FileUpload(exercise: FileUploadExercise)
    case Modeling(exercise: ModelingExercise)
    case Programming(exercise: ProgrammingExercise)
    case Quiz(exercise: QuizExercise)
    case Text(exercise: TextExercise)
    case Unknown(exercise: UnknownExercise)

    public var baseExercise: any BaseExercise {
        switch self {
        case .FileUpload(exercise: let exercise): return exercise
        case .Modeling(exercise: let exercise): return exercise
        case .Programming(exercise: let exercise): return exercise
        case .Quiz(exercise: let exercise): return exercise
        case .Text(exercise: let exercise): return exercise
        case .Unknown(exercise: let exercise): return exercise
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: Keys.type)
        switch type {
        case FileUploadExercise.type: self = .FileUpload(exercise: try FileUploadExercise(from: decoder))
        case ModelingExercise.type: self = .Modeling(exercise: try ModelingExercise(from: decoder))
        case ProgrammingExercise.type: self = .Programming(exercise: try ProgrammingExercise(from: decoder))
        case QuizExercise.type: self = .Quiz(exercise: try QuizExercise(from: decoder))
        case TextExercise.type: self = .Text(exercise: try TextExercise(from: decoder))
        default: self = .Unknown(exercise: try UnknownExercise(from: decoder))
        }
    }

    public func copyWithUpdatedParticipations(newParticipations: [Participation]) -> Exercise {
        switch self {
        case .FileUpload(exercise: let exercise):
            return .FileUpload(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        case .Modeling(exercise: let exercise):
            return .Modeling(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        case .Programming(exercise: let exercise):
            return .Programming(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        case .Quiz(exercise: let exercise):
            return .Quiz(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        case .Text(exercise: let exercise):
            return .Text(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        case .Unknown(exercise: let exercise):
            return .Unknown(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        }
    }
}

public enum Difficulty: String, Decodable {
    case EASY
    case MEDIUM
    case HARD
}

public enum Mode: String, Decodable {
    case INDIVIDUAL
    case TEAM
}

// IMPORTANT NOTICE: The following strings have to be consistent with the ones defined in Exercise.java

public enum IncludedInOverallScore: String, Decodable {
    case INCLUDED_COMPLETELY
    case INCLUDED_AS_BONUS
    case NOT_INCLUDED
}

public enum ParticipationStatus {
    case QuizNotInitialized
    case QuizActive
    case QuizSubmitted
    case QuizNotStarted
    case QuizNotParticipated
    case QuizFinished(participation: Participation)
    case NoTeamAssigned
    case Uninitialized
    case Initialized(participation: Participation)

    case Inactive(participation: Participation)

    case ExerciseActive
    case ExerciseSubmitted(participation: Participation)
    case ExerciseMissed
}

public enum AssessmentType: String, Decodable {
    case AUTOMATIC
    case SEMI_AUTOMATIC
    case MANUAL
}

public struct Category: Decodable {
    public let category: String
    public let colorCode: Int64?

    public init(from decoder: Decoder) {
        let string: String = try! decoder.singleValueContainer().decode(String.self)
        let impl = try! JSONDecoder().decode(CategoryImpl.self, from: Data(string.utf8))

        category = impl.category
        colorCode = Category.decodeColor(colorString: impl.color)
    }

    static func decodeColor(colorString: String) -> Int64? {
        if colorString.isEmpty || colorString == "null" {
            return nil
        }

        if !colorString.starts(with: "#") {
            return nil
        }

        let intCode = Int64(colorString.dropFirst(), radix: 16)
        return 0xff000000 + intCode!
    }
}

private struct CategoryImpl: Decodable {
    let category: String
    let color: String
}

public extension BaseExercise {
    // -------------------------------------------------------------
    // Copy of https://github.com/ls1intum/Artemis/blob/5c13e2e1b5b6d81594b9123946f040cbf6f0cfc6/src/main/webapp/app/exercises/shared/exercise/exercise.utils.ts
    // TODO: Remove me once this is calculated on the server.

    func computeParticipationStatus(testRun: Bool?) -> ParticipationStatus {
        let studentParticipation: Participation?
        if testRun == nil {
            studentParticipation = (studentParticipations ?? []).first
        } else {
            let foo: [Participation] = studentParticipations ?? []
            studentParticipation = foo.first { it in
                if it is StudentParticipation {
                    return (it as! StudentParticipation).testRun == testRun
                } else {
                    return false
                }
            }
        }

        // For team exercises check whether the student has been assigned to a team yet
        // !!!! TODO: Not yet implemented
        //        if (teamMode == true && studentAssignedTeamIdComputed && !studentAssignedTeamId) {
        //            return ParticipationStatus.NO_TEAM_ASSIGNED
        //        }

        // Evaluate the participation status for quiz exercises.
        if self is QuizExercise {
            return participationStatusForQuizExercise(exercise: self as! QuizExercise)
        }

        // Evaluate the participation status for modeling, text and file upload exercises if the exercise has participations.
        if (self is ModelingExercise || self is TextExercise || self is FileUploadExercise) && studentParticipation != nil {
            return participationStatusForModelingTextFileUploadExercise(participation: studentParticipation!)
        }

        let initState = studentParticipation?.baseParticipation.initializationState

        // The following evaluations are relevant for programming exercises in general and for modeling, text and file upload exercises that don't have participations.
        if studentParticipation == nil ||
                initState == InitializationState.UNINITIALIZED ||
                initState == InitializationState.REPO_COPIED ||
                initState == InitializationState.REPO_CONFIGURED ||
                initState == InitializationState.BUILD_PLAN_COPIED ||
                initState == InitializationState.BUILD_PLAN_CONFIGURED {
            if self is ProgrammingExercise && !isStartExerciseAvailable(exercise: self as! ProgrammingExercise) && testRun == nil || testRun == false {
                return ParticipationStatus.ExerciseMissed
            } else {
                return ParticipationStatus.Uninitialized
            }
        } else if studentParticipation!.baseParticipation.initializationState == InitializationState.INITIALIZED {
            return ParticipationStatus.Initialized(participation: studentParticipation!)
        }
        return ParticipationStatus.Inactive(participation: studentParticipation!)
    }

    private func isStartExerciseAvailable(exercise: ProgrammingExercise) -> Bool {
        exercise.dueDate == nil || Date() < exercise.dueDate!
    }

    private func participationStatusForQuizExercise(exercise: QuizExercise) -> ParticipationStatus {
        if exercise.status == QuizStatus.CLOSED {
            if !(exercise.studentParticipations ?? []).isEmpty && !(exercise.studentParticipations!.first!.baseParticipation.results ?? []).isEmpty {
                return ParticipationStatus.QuizFinished(participation: exercise.studentParticipations!.first!)
            }

            return ParticipationStatus.QuizNotParticipated
        } else if !(exercise.studentParticipations ?? []).isEmpty {
            let initState = exercise.studentParticipations!.first!.baseParticipation.initializationState
            if initState == InitializationState.INITIALIZED {
                return ParticipationStatus.QuizActive
            } else if initState == InitializationState.FINISHED {
                return ParticipationStatus.QuizSubmitted
            }
        } else if ((exercise.quizBatches ?? []).contains { it in
            it.started == true
        }) {
            return ParticipationStatus.QuizNotInitialized
        }
        return ParticipationStatus.QuizNotStarted
    }

    private func participationStatusForModelingTextFileUploadExercise(participation: Participation) -> ParticipationStatus {
        if participation.baseParticipation.initializationState == InitializationState.INITIALIZED {
            if hasDueDataPassed(participation: participation) {
                return ParticipationStatus.ExerciseMissed
            } else {
                return ParticipationStatus.ExerciseActive
            }
        } else if participation.baseParticipation.initializationState == InitializationState.FINISHED {
            return ParticipationStatus.ExerciseSubmitted(participation: participation)
        } else {
            return ParticipationStatus.Uninitialized
        }
    }

    private func hasDueDataPassed(participation: Participation) -> Bool {
        if dueDate == nil {
            return false
        } else {
            let dueDate = getDueDate(participation: participation)
            if dueDate == nil {
                return false
            }
            return dueDate! > Date()
        }
    }

    func getDueDate(participation: Participation) -> Date? {
        if dueDate == nil {
            return nil
        } else {
            return participation.baseParticipation.initializationDate ?? dueDate
        }
    }
}
