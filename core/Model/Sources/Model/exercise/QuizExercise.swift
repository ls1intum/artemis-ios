import Foundation

public struct QuizExercise: BaseExercise, Decodable {

    public typealias SelfType = QuizExercise

    public static var type: String {
        "quiz"
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

    public var allowedNumberOfAttempts: Int?
    public var remainingNumberOfAttempts: Int?
    public var randomizeQuestionOrder: Bool?
    public var isOpenForPractice: Bool?
    public var duration: Int?
    public var quizQuestions: [QuizQuestion]? = []
    public var status: QuizStatus?
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
    var id: Int?
    var startTime: Date?
    var started: Bool?
    var ended: Bool?
    var submissionAllowed: Bool?
    var password: String?
}
