import Foundation

struct FileUploadExercise: BaseExercise, Decodable {
    public static var type: String {
        "file-upload"
    }

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

    var filePattern: String? = nil
    var exampleSolution: String? = nil

    func copyWithUpdatedParticipations(newParticipations: [Participation]) -> BaseExercise {
        var clone = self
        clone[keyPath: \.studentParticipations] = newParticipations
        return clone
    }
}
