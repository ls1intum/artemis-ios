import Foundation

public struct TextExercise: BaseExercise, Decodable {

    public typealias SelfType = TextExercise

    public static var type: String {
        "text"
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

    public var exampleSolution: String? = nil

    public func copyWithUpdatedParticipations(newParticipations: [Participation]) -> TextExercise {
        var clone = self
        clone[keyPath: \.studentParticipations] = newParticipations
        return clone
    }
}
