//
//  SubmissionResultView.swift
//  
//
//  Created by Sven Andabaka on 21.03.23.
//

import SwiftUI
import SharedModels

private let maxValueProgrammingResultInts = 255

struct SubmissionResultView: View {
    @Environment(\.resultScorePrecision) private var inheritedPrecision

    let exercise: Exercise
    let participation: BaseParticipation
    let result: Result?
    let missingResultInfo: MissingResultInformation
    let isBuilding: Bool
    var showUngradedResult = false
    var short = false
    var scorePrecision: Int?

    var presentationState: ReviewAssessmentState {
        guard let result else { return .assessed }
        let type: String
        let rebuild: Date?
        if case .programming(let programming) = exercise { type = "programming"; rebuild = programming.buildAndTestStudentSubmissionsAfterDueDate } else { type = "other"; rebuild = nil }
        return .resolve(.init(exerciseType: type, exerciseAssessment: exercise.baseExercise.assessmentType?.rawValue, resultAssessment: result.assessmentType?.rawValue,
                              completion: result.completionDate, successful: result.successful, practice: (participation as? any StudentParticipation)?.testRun == true,
                              assessmentDue: exercise.baseExercise.assessmentDueDate, rebuild: rebuild), now: .now)
    }

    var templateStatus: ResultTemplateStatus {
        guard let result else { return .noResult }

        if result.rated == true {
            return .hasResult
        }

        return result.getTemplateStatus(for: exercise,
                                        and: participation,
                                        isBuilding: isBuilding,
                                        missingResultInfo: missingResultInfo)
    }

    var text: String {
        if [.feedbackPending, .feedbackFailed, .feedbackTimedOut].contains(presentationState) { return ReviewCopy.text(presentationState.localizationKey) }
        switch templateStatus {
        case .isBuilding:
            return R.string.localizable.building()
        case .missing:
            return R.string.localizable.programmingFailedSubmissionMesage()
        case .lateNoFeedback:
            return R.string.localizable.exerciseLateSubmission()
        case .submitted:
            return R.string.localizable.exerciseSubmitted()
        case .submittedWaitingForGrading:
            return R.string.localizable.exerciseSubmittedWaitingForGrading()
        case .late:
            if let score {
                return "\(score) \(R.string.localizable.exerciseLateFeedback())"
            }
            return R.string.localizable.exerciseLateFeedback()
        case .hasResult:
            return "\(score ?? "") (\(result?.completionDate?.relative ?? ""))"
        default:
            return showUngradedResult ? R.string.localizable.noResult() : R.string.localizable.noGradedResult()
        }
    }

    var score: String? {
        guard let result, let resultScore = result.score else {
            return nil
        }

        let precision = scorePrecision ?? inheritedPrecision
        let relativeScore = ReviewScore.rounded(resultScore, precision: precision).clean
        let points = ReviewScore.points(score: resultScore, maximum: exercise.baseExercise.maxPoints, precision: precision)?.clean ?? "—"
        switch exercise {
        case .programming:
            var resultString = ""
            if short {
                if result.testCaseCount ?? 0 > 0 {
                    resultString = R.string.localizable.short(relativeScore)
                } else {
                    resultString = R.string.localizable.programmingShort(relativeScore, buildAndTestMessage ?? "")
                }
            } else if result.codeIssueCount ?? 0 > 0 {
                resultString = R.string.localizable.programmingCodeIssues(
                    relativeScore,
                    buildAndTestMessage ?? "",
                    result.codeIssueCount ?? 0 >= maxValueProgrammingResultInts ? "\(maxValueProgrammingResultInts)+" : "\(result.codeIssueCount ?? 0)",
                    points)
            } else {
                resultString = R.string.localizable.programming(
                    relativeScore,
                    buildAndTestMessage ?? "",
                    points)
            }

            if presentationState == .preliminary {
                resultString += " (\(R.string.localizable.preliminary()))"
            }

            return resultString
        default:
            return short ? R.string.localizable.short(relativeScore) :
                R.string.localizable.nonProgramming(relativeScore, points)
        }
    }

    var buildAndTestMessage: String? {
        guard let result else {
            return nil
        }

        switch result.submission {
        case .programming(let submission):
            if submission.buildFailed ?? false {
                return R.string.localizable.buildFailed()
            }
            if (result.testCaseCount ?? 0) < 1 {
                return R.string.localizable.buildSuccessfulNoTests()
            }
            return R.string.localizable.buildSuccessfulTests(
                result.passedTestCaseCount ?? 0 >= maxValueProgrammingResultInts ? "\(maxValueProgrammingResultInts)+" : "\(result.passedTestCaseCount ?? 0)",
                result.testCaseCount ?? 0 >= maxValueProgrammingResultInts ? "\(maxValueProgrammingResultInts)+" : "\(result.testCaseCount ?? 0)")
        default:
            return nil
        }
    }

    var body: some View {
        HStack {
            if let icon = templateStatus.getIcon(for: result, assessmentState: presentationState) {
                icon
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: .extraSmallImage)
            }
            Text(text)
        }.foregroundColor(templateStatus.getColor(for: result, assessmentState: presentationState))
    }
}

extension ResultTemplateStatus {

    private func getIconName(result: Result?, assessmentState: ReviewAssessmentState?) -> String? {
        if assessmentState == .feedbackPending { return "circle-question-solid" }
        if assessmentState == .feedbackFailed || assessmentState == .feedbackTimedOut { return "circle-xmark-solid" }
        switch self {
        case .isBuilding:
            return "circle-notch-solid"
        case .hasResult, .late:
            guard let result else {
                return "circle-question-solid"
            }
            if result.isBuildFailedAndResultIsAutomatic {
                return "circle-xmark-solid"
            }
            if assessmentState == .preliminary || (assessmentState == nil && result.isResultPreliminary) {
                return "circle-question-solid"
            }
            if result.isOnlyCompilationTested(for: self) {
                return "circle-check-solid"
            }
            if result.score == nil {
                return result.successful ?? false ? "circle-check-solid" : "circle-xmark-solid"
            }
            if result.score! >= MIN_SCORE_GREEN {
                return "circle-check-solid"
            }
            return "circle-xmark-solid"
        case .submitted, .submittedWaitingForGrading, .lateNoFeedback:
            return nil
        case .missing:
            return "circle-exclamation-solid"
        default:
            return "circle-solid"
        }
    }

    func getIcon(for result: Result?, assessmentState: ReviewAssessmentState? = nil) -> Image? {
        guard let iconName = getIconName(result: result, assessmentState: assessmentState) else {
            return nil
        }
        return Image(iconName, bundle: .module)
    }

    func getColor(for result: Result?, assessmentState: ReviewAssessmentState? = nil) -> Color {
        if let override = assessmentState?.badgeColor { return override }
        switch self {
        case .isBuilding:
            return Color.Artemis.primaryLabel
        case .late:
            return Color.Artemis.resultLateColor
        case .missing:
            return Color.Artemis.resultFailedColor
        case .hasResult:
            guard let result else {
                return Color.Artemis.resultPendingColor
            }

            if result.isBuildFailedAndResultIsAutomatic {
                return Color.Artemis.resultFailedColor
            }
            if assessmentState == .preliminary || (assessmentState == nil && result.isResultPreliminary) {
                return Color.Artemis.resultPendingColor
            }
            if result.score == nil {
                return result.successful ?? false ? Color.Artemis.resultSuccess : Color.Artemis.resultFailedColor
            }
            if result.isOnlyCompilationTested(for: self) {
                return Color.Artemis.resultSuccess
            }
            if result.score! >= MIN_SCORE_GREEN {
                return Color.Artemis.resultSuccess
            }
            if result.score! >= MIN_SCORE_ORANGE {
                return Color.Artemis.resultSuccessBelowScore
            }
            return Color.Artemis.resultFailedColor
        default:
            return Color.Artemis.resultPendingColor
        }
    }
}

extension Double {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

private extension ReviewAssessmentState {
    var badgeColor: Color? {
        switch self {
        case .feedbackPending: Color.Artemis.resultPendingColor
        case .feedbackFailed, .feedbackTimedOut: Color.Artemis.resultFailedColor
        default: nil
        }
    }
}
