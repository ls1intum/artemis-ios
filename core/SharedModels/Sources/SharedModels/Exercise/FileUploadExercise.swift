import Foundation

public struct FileUploadExercise: BaseExercise, Decodable {
    public typealias SelfType = FileUploadExercise

    public static var type: String {
        "file-upload"
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

    public var filePattern: String?
    public var exampleSolution: String?

    public func copyWithUpdatedParticipations(newParticipations: [Participation]) -> FileUploadExercise {
        var clone = self
        clone[keyPath: \.studentParticipations] = newParticipations
        return clone
    }
}