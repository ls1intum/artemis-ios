import Foundation

struct QuizExercise: BaseExercise, Decodable {

    typealias SelfType = QuizExercise

    public static var type: String {
        "quiz"
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

    var allowedNumberOfAttempts: Int? = nil
    var remainingNumberOfAttempts: Int? = nil
    var randomizeQuestionOrder: Bool? = nil
    var isOpenForPractice: Bool? = nil
    var duration: Int? = nil
    var quizQuestions: [QuizQuestion] = []
    var status: QuizStatus? = nil
    var quizMode: QuizMode = QuizMode.INDIVIDUAL
    var quizBatches: [QuizBatch] = []

    func copyWithUpdatedParticipations(newParticipations: [Participation]) -> QuizExercise {
        var clone = self
        clone[keyPath: \.studentParticipations] = newParticipations
        return clone
    }
}

enum QuizStatus: Decodable {
    case CLOSED
    case OPEN_FOR_PRACTICE
    case ACTIVE
    case VISIBLE
    case INVISIBLE
}

enum QuizMode: Decodable {
    case SYNCHRONIZED
    case BATCHED
    case INDIVIDUAL
}

struct QuizBatch: Decodable {
    var id: Int? = nil
    var startTime: Date? = nil
    var started: Bool? = nil
    var ended: Bool? = nil
    var submissionAllowed: Bool? = nil
    var password: String? = nil
}