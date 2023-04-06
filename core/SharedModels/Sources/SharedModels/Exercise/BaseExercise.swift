import Foundation
import SwiftUI

public protocol BaseExercise: Codable {
    associatedtype SelfType: BaseExercise

    static var type: String { get }

    var id: Int { get }
    var title: String? { get }
    var shortName: String? { get }
    var maxPoints: Double? { get }
    var bonusPoints: Double? { get }
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
    var studentAssignedTeamIdComputed: Bool? { get }
    var studentAssignedTeamId: Int? { get }

    // -------
    var attachments: [Attachment]? { get }

    /**
     * Create a copy of this exercise with the participations field replaced.
     */
    func copyWithUpdatedParticipations(newParticipations: [Participation]) -> SelfType
}

public enum Exercise: Codable, Identifiable {

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
        baseExercise.id
    }

    public var image: Image {
        switch self {
        case .fileUpload:
            return Image("file-arrow-up-solid", bundle: .module)
        case .modeling:
            return Image("diagram-project-solid", bundle: .module)
        case .programming:
            return Image("keyboard-solid", bundle: .module)
        case .quiz:
            return Image("check-double-solid", bundle: .module)
        case .text:
            return Image("font-solid", bundle: .module)
        case .unknown:
            return Image("question-solid", bundle: .module)
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

    public func getSpecificStudentParticipation(testRun: Bool) -> StudentParticipation? {
        let studentParticipation = (baseExercise.studentParticipations ?? []).first(where: { participation in
            switch participation {
            case .student(let participation):
                return (participation.testRun ?? false) == testRun
            case .programmingExerciseStudent(let participation):
                return (participation.testRun ?? false) == testRun
            default:
                return false
            }
        })

        switch studentParticipation {
        case .student(let participation):
            return participation
        case .programmingExerciseStudent(let participation):
            return participation
        default:
            return nil
        }
    }

    public func getDueDate(for participation: BaseParticipation) -> Date? {
        guard let dueDate = baseExercise.dueDate else { return nil }
        return participation.initializationDate ?? dueDate
    }
}

public enum Difficulty: String, Codable {
    case EASY
    case MEDIUM
    case HARD

    public var description: String {
        switch self {
        case .EASY:
            return R.string.localizable.difficulty_easy()
        case .MEDIUM:
            return R.string.localizable.difficulty_medium()
        case .HARD:
            return R.string.localizable.difficulty_hard()
        }
    }

    public var color: Color {
        switch self {
        case .EASY:
            return Color.Artemis.badgeSuccessColor
        case .MEDIUM:
            return Color.Artemis.badgeWarningColor
        case .HARD:
            return Color.Artemis.badgeDangerColor
        }
    }
}

public enum Mode: String, Codable {
    case individual = "INDIVIDUAL"
    case team = "TEAM"
}

// IMPORTANT NOTICE: The following strings have to be consistent with the ones defined in Exercise.java

public enum IncludedInOverallScore: String, Codable {
    case includedCompletly = "INCLUDED_COMPLETELY"
    case includedAsBonus = "INCLUDED_AS_BONUS"
    case notIncluded = "NOT_INCLUDED"

    public var description: String {
        switch self {
        case .includedCompletly:
            return R.string.localizable.includedInOverallScore_includedCompletely()
        case .includedAsBonus:
            return R.string.localizable.includedInOverallScore_includedAsBonus()
        case .notIncluded:
            return R.string.localizable.includedInOverallScore_notIncluded()
        }
    }

    public var color: Color {
        switch self {
        case .includedCompletly:
            return Color.Artemis.badgeSuccessColor
        case .includedAsBonus:
            return Color.Artemis.badgeWarningColor
        case .notIncluded:
            return Color.Artemis.badgeSecondaryColor
        }
    }
}

public enum AssessmentType: String, Codable {
    case automatic = "AUTOMATIC"
    case semiAutomatic = "SEMI_AUTOMATIC"
    case manual = "MANUAL"

    // TODO: localization
    public var description: String {
        switch self {
        case .automatic:
            return "automatic"
        case .semiAutomatic:
            return "semi-automatic"
        case .manual:
            return "manual"
        }
    }
}

public struct Category: Codable {
    public let category: String
    public let colorCode: String

    // TODO: remove force unwrap
    // swiftlint:disable force_try
    public init(from decoder: Decoder) {
        let string: String = try! decoder.singleValueContainer().decode(String.self)
        let impl = try! JSONDecoder().decode(CategoryImpl.self, from: Data(string.utf8))

        category = impl.category
        colorCode = impl.color
    }
}

private struct CategoryImpl: Codable {
    let category: String
    let color: String
}

extension Exercise: Hashable {
    public static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
