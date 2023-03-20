import Foundation
import SwiftUI

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
    var releaseDate: Date? { get }
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

public enum Exercise: Decodable, Identifiable {

    fileprivate enum Keys: String, CodingKey {
        case type
    }

    case fileUpload(exercise: FileUploadExercise)
    case modeling(exercise: ModelingExercise)
    case programming(exercise: ProgrammingExercise)
    case quiz(exercise: QuizExercise)
    case text(exercise: TextExercise)
    case unknown(exercise: UnknownExercise)

    public var baseExercise: any BaseExercise {
        switch self {
        case .fileUpload(exercise: let exercise): return exercise
        case .modeling(exercise: let exercise): return exercise
        case .programming(exercise: let exercise): return exercise
        case .quiz(exercise: let exercise): return exercise
        case .text(exercise: let exercise): return exercise
        case .unknown(exercise: let exercise): return exercise
        }
    }

    public var id: Int {
        baseExercise.id ?? -1 // TODO: why optional
    }

    // TODO: adjust image
    public var image: Image {
        switch self {
//        case .fileUpload(let exercise):
//            return Image(systemName: "")
//        case .modeling(let exercise):
//            <#code#>
//        case .programming(let exercise):
//            <#code#>
//        case .quiz(let exercise):
//            <#code#>
//        case .text(let exercise):
//            <#code#>
//        case .unknown(let exercise):
//            <#code#>
        default:
            return Image(systemName: "doc.text.fill")
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: Keys.type)
        switch type {
        case FileUploadExercise.type: self = .fileUpload(exercise: try FileUploadExercise(from: decoder))
        case ModelingExercise.type: self = .modeling(exercise: try ModelingExercise(from: decoder))
        case ProgrammingExercise.type: self = .programming(exercise: try ProgrammingExercise(from: decoder))
        case QuizExercise.type: self = .quiz(exercise: try QuizExercise(from: decoder))
        case TextExercise.type: self = .text(exercise: try TextExercise(from: decoder))
        default: self = .unknown(exercise: try UnknownExercise(from: decoder))
        }
    }

    public func copyWithUpdatedParticipations(newParticipations: [Participation]) -> Exercise {
        switch self {
        case .fileUpload(exercise: let exercise):
            return .fileUpload(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        case .modeling(exercise: let exercise):
            return .modeling(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        case .programming(exercise: let exercise):
            return .programming(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        case .quiz(exercise: let exercise):
            return .quiz(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        case .text(exercise: let exercise):
            return .text(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        case .unknown(exercise: let exercise):
            return .unknown(exercise: exercise.copyWithUpdatedParticipations(newParticipations: newParticipations))
        }
    }
}

public enum Difficulty: String, Decodable {
    case EASY
    case MEDIUM
    case HARD

    // TODO: localize
    public var description: String {
        switch self {
        case .EASY:
            return "Easy"
        case .MEDIUM:
            return "Medium"
        case .HARD:
            return "Hard"
        }
    }
}

public enum Mode: String, Decodable {
    case INDIVIDUAL
    case TEAM
}

// IMPORTANT NOTICE: The following strings have to be consistent with the ones defined in Exercise.java

public enum IncludedInOverallScore: String, Decodable {
    case includedCompletly = "INCLUDED_COMPLETELY"
    case includedAsBonus = "INCLUDED_AS_BONUS"
    case notIncluded = "NOT_INCLUDED"

    // TODO: localize
    public var description: String {
        switch self {
        case .includedCompletly:
            return "TODO"
        case .includedAsBonus:
            return "Bonus"
        case .notIncluded:
            return "TODO"
        }
    }
}

public enum ParticipationStatus {
    case quizNotInitialized
    case quizActive
    case quizSubmitted
    case quizNotStarted
    case quizNotParticipated
    case quizFinished(participation: Participation)
    case noTeamAssigned
    case uninitialized
    case initialized(participation: Participation)

    case inactive(participation: Participation)

    case exerciseActive
    case exerciseSubmitted(participation: Participation)
    case exerciseMissed
}

public enum AssessmentType: String, Decodable {
    case automatic = "AUTOMATIC"
    case semiAutomatic = "SEMI_AUTOMATIC"
    case manual = "MANUAL"
}

public struct Category: Decodable {
    public let category: String
    public let colorCode: String
}

// swiftlint:disable force_cast
public extension BaseExercise {
    // -------------------------------------------------------------
    // Copy of https://github.com/ls1intum/Artemis/blob/5c13e2e1b5b6d81594b9123946f040cbf6f0cfc6/src/main/webapp/app/exercises/shared/exercise/exercise.utils.ts
    // TODO: Remove me once this is calculated on the server.

    func computeParticipationStatus(testRun: Bool?) -> ParticipationStatus {
        let studentParticipation: Participation?
        if testRun == nil {
            studentParticipation = (studentParticipations ?? []).first
        } else {
            let participations: [Participation] = studentParticipations ?? []
            studentParticipation = participations.first { participation in
                if participation is StudentParticipation {
                    return (participation as! StudentParticipation).testRun == testRun
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
            initState == InitializationState.uninitalized ||
            initState == InitializationState.repoCopied ||
            initState == InitializationState.repoConfigured ||
            initState == InitializationState.buildPlanCopied ||
            initState == InitializationState.buildPlanConfigured {
            if self is ProgrammingExercise && !isStartExerciseAvailable(exercise: self as! ProgrammingExercise) && testRun == nil || testRun == false {
                return ParticipationStatus.exerciseMissed
            } else {
                return ParticipationStatus.uninitialized
            }
        } else if studentParticipation!.baseParticipation.initializationState == InitializationState.INITIALIZED {
            return ParticipationStatus.initialized(participation: studentParticipation!)
        }
        return ParticipationStatus.inactive(participation: studentParticipation!)
    }

    private func isStartExerciseAvailable(exercise: ProgrammingExercise) -> Bool {
        exercise.dueDate == nil || Date() < exercise.dueDate!
    }

    private func participationStatusForQuizExercise(exercise: QuizExercise) -> ParticipationStatus {
        if exercise.status == QuizStatus.closed {
            if !(exercise.studentParticipations ?? []).isEmpty && !(exercise.studentParticipations!.first!.baseParticipation.results ?? []).isEmpty {
                return ParticipationStatus.quizFinished(participation: exercise.studentParticipations!.first!)
            }

            return ParticipationStatus.quizNotParticipated
        } else if !(exercise.studentParticipations ?? []).isEmpty {
            let initState = exercise.studentParticipations!.first!.baseParticipation.initializationState
            if initState == InitializationState.INITIALIZED {
                return ParticipationStatus.quizActive
            } else if initState == InitializationState.FINISHED {
                return ParticipationStatus.quizSubmitted
            }
        } else if ((exercise.quizBatches ?? []).contains { item in
            item.started == true
        }) {
            return ParticipationStatus.quizNotInitialized
        }
        return ParticipationStatus.quizNotStarted
    }

    private func participationStatusForModelingTextFileUploadExercise(participation: Participation) -> ParticipationStatus {
        if participation.baseParticipation.initializationState == InitializationState.INITIALIZED {
            if hasDueDataPassed(participation: participation) {
                return ParticipationStatus.exerciseMissed
            } else {
                return ParticipationStatus.exerciseActive
            }
        } else if participation.baseParticipation.initializationState == InitializationState.FINISHED {
            return ParticipationStatus.exerciseSubmitted(participation: participation)
        } else {
            return ParticipationStatus.uninitialized
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
