import Foundation

public struct QuizExercise: BaseExercise {

    public typealias SelfType = QuizExercise

    public static var type: String {
        "quiz"
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

    public var allowedNumberOfAttempts: Int?
    public var remainingNumberOfAttempts: Int?
    public var randomizeQuestionOrder: Bool?
    public var isOpenForPractice: Bool?
    public var duration: Int?
    public var quizQuestions: [QuizQuestion]? = []
    public var status: QuizStatus?
    public var quizMode: QuizMode? = QuizMode.INDIVIDUAL
    public var quizEnded: Bool?
    public var quizBatches: [QuizBatch]? = []

    public func copyWithUpdatedParticipations(newParticipations: [Participation]) -> QuizExercise {
        var clone = self
        clone[keyPath: \.studentParticipations] = newParticipations
        return clone
    }

    public var isUninitialized: Bool {
        notEndedSubmittedOrFinished && startedQuizBatch
    }

    public var notStarted: Bool {
        notEndedSubmittedOrFinished && !startedQuizBatch
    }

    private var notEndedSubmittedOrFinished: Bool {
        !(quizEnded ?? false)
        && (studentParticipations?.first?.baseParticipation.initializationState == nil
            || [InitializationState.initialized, InitializationState.finished].contains(
                studentParticipations?.first?.baseParticipation.initializationState)
        )
    }

    private var startedQuizBatch: Bool {
        (quizBatches ?? []).contains(where: { $0.started ?? false })
    }
}

public enum QuizStatus: String, RawRepresentable, Codable {
    case closed = "CLOSED"
    case openForPractice = "OPEN_FOR_PRACTICE"
    case active = "ACTIVE"
    case visible = "VISIBLE"
    case invisible = "INVISIBLE"
}

public enum QuizMode: String, RawRepresentable, Codable {
    case SYNCHRONIZED
    case BATCHED
    case INDIVIDUAL
}

public struct QuizBatch: Codable {
    var id: Int?
    var startTime: Date?
    var started: Bool?
    var ended: Bool?
    var submissionAllowed: Bool?
    var password: String?
}
