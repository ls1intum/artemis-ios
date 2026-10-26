import Foundation

/// Mirrors programming-exercise.utils.ts and result.utils.ts using authorized DTO fields.
enum ReviewAssessmentState: Equatable {
    case assessed, preliminary, feedbackPending, feedbackFailed, feedbackTimedOut
    struct Input {
        let exerciseType: String
        let exerciseAssessment: String?
        let resultAssessment: String?
        let completion: Date?
        let successful: Bool?
        let practice: Bool
        let assessmentDue: Date?
        let rebuild: Date?
    }
    static func resolve(_ input: Input, now: Date) -> Self {
        let exerciseType = input.exerciseType, exerciseAssessment = input.exerciseAssessment, resultAssessment = input.resultAssessment
        let completion = input.completion, successful = input.successful, practice = input.practice
        let assessmentDue = input.assessmentDue, rebuild = input.rebuild
        if resultAssessment == "AUTOMATIC_ATHENA" {
            if successful == true { return .preliminary }
            if successful == false { return .feedbackFailed }
            if let completion, completion < now { return .feedbackTimedOut }
            return .feedbackPending
        }
        guard exerciseType == "programming", !practice else { return .assessed }
        guard let completion else { return .preliminary }
        if exerciseAssessment != "AUTOMATIC" {
            if resultAssessment == "MANUAL" || resultAssessment == "SEMI_AUTOMATIC" { return .assessed }
            if let assessmentDue { return now < assessmentDue ? .preliminary : .assessed }
            return resultAssessment == "AUTOMATIC" ? .preliminary : .assessed
        }
        if let rebuild, completion < rebuild { return .preliminary }
        return .assessed
    }
    var localizationKey: String {
        switch self {
        case .assessed: "review.assessed"
        case .preliminary: "review.preliminary"
        case .feedbackPending: "review.feedbackPending"
        case .feedbackFailed: "review.feedbackFailed"
        case .feedbackTimedOut: "review.feedbackTimedOut"
        }
    }
}
