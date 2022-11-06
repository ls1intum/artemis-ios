import Foundation

struct ProgrammingExercise: Exercise, Decodable {
    var id: Int? = nil
    var title: String? = nil
    var shortName: String? = nil
    var maxPoints: Float? = nil
    var bonusPoints: Float? = nil
    var releaseDate: Date? = nil
    var dueDate: Date? = nil
    var assessmentDueDate: Date? = nil
    var difficulty: Difficulty? = nil
    var mode: Mode = .INDIVIDUAL
    var categories: [Category] = []
    var visibleToStudents: Bool? = nil
    var teamMode: Bool? = nil
    var problemStatement: String? = nil
    var assessmentType: AssessmentType? = nil
    var allowComplaintsForAutomaticAssessments: Bool? = nil
    var allowManualFeedbackRequests: Bool? = nil
    var includedInOverallScore: IncludedInOverallScore = .INCLUDED_COMPLETELY
    var exampleSolutionPublicationDate: Date? = nil
    var studentParticipations: [Participation]? = nil
    var attachments: [Attachment] = []
    var programmingLanguage: ProgrammingLanguage? = nil

    func copyWithUpdatedParticipations(newParticipations: [Participation]) -> Exercise {
        var clone = self
        clone[keyPath: \.studentParticipations] = newParticipations
        return clone
    }
}

enum ProgrammingLanguage: Decodable {
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