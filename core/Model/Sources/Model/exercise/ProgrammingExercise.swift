import Foundation

public struct ProgrammingExercise: BaseExercise, Decodable {
    public typealias SelfType = ProgrammingExercise

    public static var type: String {
        "programming"
    }

    public var id: Int? = nil
    public var title: String? = nil
    public var shortName: String? = nil
    public var maxPoints: Float? = nil
    public var bonusPoints: Float? = nil
    public var releaseDate: Date? = nil
    public var dueDate: Date? = nil
    public var assessmentDueDate: Date? = nil
    public var difficulty: Difficulty? = nil
    public var mode: Mode = .INDIVIDUAL
    public var categories: [Category]? = []
    public var visibleToStudents: Bool? = nil
    public var teamMode: Bool? = nil
    public var problemStatement: String? = nil
    public var assessmentType: AssessmentType? = nil
    public var allowComplaintsForAutomaticAssessments: Bool? = nil
    public var allowManualFeedbackRequests: Bool? = nil
    public var includedInOverallScore: IncludedInOverallScore = .INCLUDED_COMPLETELY
    public var exampleSolutionPublicationDate: Date? = nil
    public var studentParticipations: [Participation]? = nil
    public var attachments: [Attachment]? = []
    public var programmingLanguage: ProgrammingLanguage? = nil

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