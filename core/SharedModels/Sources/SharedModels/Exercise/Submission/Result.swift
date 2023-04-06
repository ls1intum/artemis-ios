import Foundation

public struct Result: Codable {
    public var id: Int?
    public var completionDate: Date?
    public var successful: Bool?
    public var hasFeedback: Bool?
    /**
     * Current score in percent i.e. between 1 - 100
     * - Can be larger than 100 if bonus points are available
     */
    public var score: Double?
    public var assessmentType: AssessmentType?
    public var rated: Bool?
    public var hasComplaint: Bool?
    public var exampleResult: Bool?
    public var testCaseCount: Int?
    public var passedTestCaseCount: Int?
    public var codeIssueCount: Int?
    public var submission: Submission?
    public var assessor: User?
    // val feedbacks: List<Feedback>? = nil,
    public var participation: Participation?

    // swiftlint:disable:next identifier_name
    public var isProgrammingExerciseStudentParticipation: Bool {
        switch participation {
        case .programmingExerciseStudent:
            return true
        default:
            return false
        }
    }

    /**
     * A result is preliminary if:
     * - The programming exercise buildAndTestAfterDueDate is set
     * - The submission date of the result / result completionDate is before the buildAndTestAfterDueDate
     *
     * Note: We check some error cases in this method as a null value for the given parameters, because the clients using this method might unwillingly provide them (result component).
     */
    public var isResultPreliminary: Bool {
        guard let exercise = participation?.baseParticipation.exercise else { return false }

        switch exercise {
        case .programming(let exercise):
            switch participation {
            case .programmingExerciseStudent(let participation):
                if participation.testRun ?? false {
                    return false
                }
            default:
                // do nothing
                print("do nothing")
            }

            // We use the result completion date
            guard let completionDate else {
                // in the unlikely case the completion date is not set yet (this should not happen), it is preliminary
                return true
            }

            // If an exercise's assessment type is not automatic the last result is supposed to be manually assessed
            if exercise.assessmentType != .automatic {
                // either the semi-automatic result is not yet available as last result (then it is preliminary), or it is already available (then it still can be changed)
                if let assessmentDueDate = exercise.assessmentDueDate {
                    return assessmentDueDate > .now
                }
                // in case the assessment due date is not set, the assessment type of the latest result is checked. If it is automatic the result is still preliminary.
                return assessmentType == .automatic
            }
            // swiftlint:disable:next identifier_name
            if let buildAndTestStudentSubmissionsAfterDueDate = exercise.buildAndTestStudentSubmissionsAfterDueDate {
                return completionDate < buildAndTestStudentSubmissionsAfterDueDate
            }
            return false
        default:
            return false
        }
    }

    public var isBuildFailedAndResultIsAutomatic: Bool {
        isBuildFailed && !isManualResult
    }

    public var isBuildFailed: Bool {
        switch submission {
        case .programming(let submission):
            return submission.buildFailed ?? false
        default:
            return false
        }
    }

    public var isManualResult: Bool {
        assessmentType != .automatic
    }

    /**
     * Checks if only compilation was tested. This is the case, when a successful result is present with 0 of 0 passed tests
     * This could be because all test cases are only visible after the due date.
     */
    public func isOnlyCompilationTested(for templateStatus: ResultTemplateStatus) -> Bool {
        let zeroTests = (testCaseCount ?? 0) == 0
        switch participation {
        case .programmingExerciseStudent(let participation):
            if case .programming = participation.exercise {
                return templateStatus != .noResult &&
                    templateStatus != .isBuilding &&
                    !isBuildFailed &&
                    zeroTests
            }
            return false
        default:
            return false
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    public func getTemplateStatus(for exercise: Exercise,
                                  and participation: BaseParticipation,
                                  isBuilding: Bool,
                                  missingResultInfo: MissingResultInformation = .noInformation) -> ResultTemplateStatus {
        // If there is a problem, it has priority, and we show that instead
        if missingResultInfo != .noInformation {
            return .missing
        }

        switch exercise {
        case .fileUpload, .modeling, .text:
            let inDueTime = participation.isInDueTime(exercise: exercise)
            let dueTime = exercise.getDueDate(for: participation)
            let assessmentDueDate = exercise.baseExercise.assessmentDueDate

            if inDueTime,
               score != nil {
                // Submission is in due time of exercise and has a result with score
                if assessmentDueDate ?? .yesterday < .now {
                    // the assessment due date has passed (or there was none)
                    return .hasResult
                } else {
                    // the assessment period is still active
                    return .submittedWaitingForGrading
                }
            } else if inDueTime && score == nil {
                // Submission is in due time of exercise and doesn't have a result with score.
                if dueTime == nil || dueTime! >= .now {
                    // the due date is in the future (or there is none) => the exercise is still ongoing
                    return .submitted
                } else if assessmentDueDate == nil || assessmentDueDate! >= .now {
                    // the due date is over, further submissions are no longer possible, waiting for grading
                    return .submittedWaitingForGrading
                } else {
                    // the due date is over, further submissions are no longer possible, no result after assessment due date
                    // TODO: why is this distinct from the case above? The submission can still be graded and often is.
                    return .noResult
                }
            } else if score != nil,
                      (assessmentDueDate == nil || assessmentDueDate! >= .now) {
                // Submission is not in due time of exercise, has a result with score and there is no assessmentDueDate for the exercise or it lies in the past.
                // TODO: handle external submissions with new status "External"
                return .late
            } else {
                // Submission is not in due time of exercise and there is actually no feedback for the submission or the feedback should not be displayed yet.
                return .lateNoFeedback
            }
        case .quiz, .programming:
            if isBuilding {
                return .isBuilding
            } else if score != nil {
                return .hasResult
            } else {
                return .noResult
            }
        default:
            return .noResult
        }
    }
}

public enum ResultTemplateStatus: String, RawRepresentable, Codable {
    /**
     * An automatic result is currently being generated and should be available soon.
     * This is currently only relevant for programming exercises.
     */
    case isBuilding = "IS_BUILDING"
    /**
     * A regular, finished result is available.
     * Can be rated (counts toward the score) or not rated (after the deadline for practice).
     */
    case hasResult = "HAS_RESULT"
    /**
     * There is no result or submission status that could be shown, e.g. because the student just started with the exercise.
     */
    case noResult = "NO_RESULT"
    /**
     * Submitted and the student can still continue to submit.
     */
    case submitted = "SUBMITTED"
    /**
     * Submitted and the student can no longer submit, but a result is not yet available.
     */
    case submittedWaitingForGrading = "SUBMITTED_WAITING_FOR_GRADING"
    /**
     * The student started the exercise but submitted too late.
     * Feedback is not yet available, and a future result will not count toward the score.
     */
    case lateNoFeedback = "LATE_NO_FEEDBACK"
    /**
     * The student started the exercise and submitted too late, but feedback is available.
     */
    case late = "LATE"
    /**
     * No latest result available, e.g. because building took too long and the webapp did not receive it in time.
     * This is a distinct state because we want the student to know about this problematic state
     * and not confuse them by showing a previous result that does not match the latest submission.
     */
    case missing = "MISSING"
}

/**
 * Information about a missing result to communicate problems and give hints how to respond.
 */
public enum MissingResultInformation: String, RawRepresentable, Codable {
    case noInformation = "NONE"
    case failedProgrammingSubmissionOnlineIDE = "FAILED_PROGRAMMING_SUBMISSION_ONLINE_IDE"
    case failedProgrammingSubmissionOfflineIDE = "FAILED_PROGRAMMING_SUBMISSION_OFFLINE_IDE"
}
