import Foundation

public struct FileUploadExercise: BaseExercise {

    public typealias SelfType = FileUploadExercise

    public static var type: String {
        "file-upload"
    }

    public var id: Int
    public var title: String?
    public var shortName: String?
    public var maxPoints: Double?
    public var bonusPoints: Double?
    public var dueDate: Date?
    public var releaseDate: Date?
    public var assessmentDueDate: Date?
    public var difficulty: Difficulty?
    public var mode: Mode = .individual
    public var categories: [Category]? = []
    public var visibleToStudents: Bool?
    public var teamMode: Bool?
    public var problemStatement: String?
    public var assessmentType: AssessmentType?
    public var allowComplaintsForAutomaticAssessments: Bool?
    public var allowManualFeedbackRequests: Bool?
    public var includedInOverallScore: IncludedInOverallScore = .includedCompletly
    public var exampleSolutionPublicationDate: Date?
    public var studentParticipations: [Participation]?
    public var attachments: [Attachment]? = []
    public var studentAssignedTeamIdComputed: Bool?
    public var studentAssignedTeamId: Int?

    public var filePattern: String?
    public var exampleSolution: String?

    public func copyWithUpdatedParticipations(newParticipations: [Participation]) -> FileUploadExercise {
        var clone = self
        clone[keyPath: \.studentParticipations] = newParticipations
        return clone
    }
}
