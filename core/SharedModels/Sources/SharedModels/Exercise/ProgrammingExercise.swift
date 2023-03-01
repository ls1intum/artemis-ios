import Foundation

public struct ProgrammingExercise: BaseExercise, Decodable {
    public typealias SelfType = ProgrammingExercise

    public static var type: String {
        "programming"
    }

    public var id: Int?
    public var title: String?
    public var shortName: String?
    public var maxPoints: Float?
    public var bonusPoints: Float?
//    public var releaseDate: Date?
    public var dueDate: Date?
    public var assessmentDueDate: Date?
    public var difficulty: Difficulty?
    public var mode: Mode = .INDIVIDUAL
    public var categories: [Category]? = []
    public var visibleToStudents: Bool?
    public var teamMode: Bool?
    public var problemStatement: String?
    public var assessmentType: AssessmentType?
    public var allowComplaintsForAutomaticAssessments: Bool?
    public var allowManualFeedbackRequests: Bool?
    public var includedInOverallScore: IncludedInOverallScore = .INCLUDED_COMPLETELY
    public var exampleSolutionPublicationDate: Date?
    public var studentParticipations: [Participation]?
    public var attachments: [Attachment]? = []
    public var programmingLanguage: ProgrammingLanguage?

    public func copyWithUpdatedParticipations(newParticipations: [Participation]) -> ProgrammingExercise {
        var clone = self
        clone[keyPath: \.studentParticipations] = newParticipations
        return clone
    }
}

public enum ProgrammingLanguage: String, Decodable {
    case JAVA
    case PYTHON
    case C
    case HASKELL
    case KOTLIN
    case VHDL
    case ASSEMBLER
    case SWIFT
    case OCAML
    case EMPTY
}
