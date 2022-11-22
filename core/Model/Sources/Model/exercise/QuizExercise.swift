import Foundation

public struct QuizExercise: BaseExercise, Decodable {

    public typealias SelfType = QuizExercise

    public static var type: String {
        "quiz"
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

    public var allowedNumberOfAttempts: Int? = nil
    public var remainingNumberOfAttempts: Int? = nil
    public var randomizeQuestionOrder: Bool? = nil
    public var isOpenForPractice: Bool? = nil
    public var duration: Int? = nil
    public var quizQuestions: [QuizQuestion]? = []
    public var status: QuizStatus? = nil
    public var quizMode: QuizMode? = QuizMode.INDIVIDUAL
    public var quizBatches: [QuizBatch]? = []

    public func copyWithUpdatedParticipations(newParticipations: [Participation]) -> QuizExercise {
        var clone = self
        clone[keyPath: \.studentParticipations] = newParticipations
        return clone
    }
}

public enum QuizStatus: String, Decodable {
    case CLOSED
    case OPEN_FOR_PRACTICE
    case ACTIVE
    case VISIBLE
    case INVISIBLE
}

public enum QuizMode: String, Decodable {
    case SYNCHRONIZED
    case BATCHED
    case INDIVIDUAL
}

public struct QuizBatch: Decodable {
    var id: Int? = nil
    var startTime: Date? = nil
    var started: Bool? = nil
    var ended: Bool? = nil
    var submissionAllowed: Bool? = nil
    var password: String? = nil
}