import Foundation
import SwiftUI
import Factory
import Model
import Websocket
import Data

private let MIN_SCORE_GREEN: Float = 80.0
private let MIN_SCORE_ORANGE: Float = 40.0

private let colorResultSuccess: Color = Color(red: 0, green: 1, blue: 0)
private let colorResultMedium: Color = Color(red: 1, green: 1, blue: 0)
private let colorResulBad: Color = Color(red: 1, green: 0, blue: 0)

private let statusFont: Font = .callout

/**
 * Enumeration object representing the possible options that
 * the status of the result's template can be in.
 */
private enum ResultTemplateStatus {
    /**
     * An automatic result is currently being generated and should be available soon.
     * This is currently only relevant for programming exercises.
     */
    case IsBuilding

    /**
     * A regular, finished result is available.
     * Can be rated (counts toward the score) or not rated (after the deadline for practice).
     */
    case HasResult(result: Result)

    /**
     * There is no result or submission status that could be shown, e.g. because the student just started with the exercise.
     */
    case NoResult

    /**
     * Submitted and the student can still continue to submit.
     */
    case Submitted

    /**
     * Submitted and the student can no longer submit, but a result is not yet available.
     */
    case SubmittedWaitingForGrading

    /**
     * The student started the exercise but submitted too late.
     * Feedback is not yet available, and a future result will not count toward the score.
     */
    case LateNoFeedback

    /**
     * The student started the exercise and submitted too late, but feedback is available.
     */
    case Late(result: Result)

    /**
     * No latest result available, e.g. because building took too long and the webapp did not receive it in time.
     * This is a distinct state because we want the student to know about this problematic state
     * and not confuse them by showing a previous result that does not match the latest submission.
     */
    case Missing
}

private class ExerciseResultViewController: ObservableObject {

    @Published var isBuilding: Bool = false
    @Published var templateStatus: ResultTemplateStatus = .NoResult

    init(participation: Participation, exercise: Exercise, personal: Bool, showUngradedResults: Bool, result: Result?) {
        let participationService = ParticipationServiceFactory.shared
        let isBuildingObservable = participationService
                .getLatestPendingSubmissionByParticipationIdObservable(
                        participationId: participation.baseParticipation.id ?? 0,
                        exerciseId: exercise.baseExercise.id ?? 0,
                        personal: personal,
                        fetchPending: true
                )
        
//                .filter { submissionData in
//                    let shouldUpdateBasedOnData: Bool
//
//                    if let subData = submissionData {
//                        switch subData {
//                        case .IsBuildingPendingSubmission(participationId: _, submission: let submission):
//                            switch submission {
//                            case .Instructor(_), .Test(_): shouldUpdateBasedOnData = true
//                            default:
//                                let submissionDate = submission.baseSubmission.submissionDate?.date ?? Date(timeIntervalSince1970: 0)
//                                let dueDate: Date = exercise.baseExercise.getDueDate(participation: participation) ?? Date(timeIntervalSince1970: 0)
//
//                                shouldUpdateBasedOnData = submissionDate < dueDate
//                            }
//                        case .NoPendingSubmission(participationId: _):
//                            shouldUpdateBasedOnData = true
//                        case .FailedSubmission(participationId: _):
//                            shouldUpdateBasedOnData = true
//                        }
//                    } else {
//                        shouldUpdateBasedOnData = true
//                    }
//
//                    return showUngradedResults || exercise.baseExercise.dueDate == nil || shouldUpdateBasedOnData
//                }
//                .map { submissionData in
//                    switch submissionData {
//                    case .IsBuildingPendingSubmission(_, _): return true
//                    default: return false
//                    }
//                }

//        isBuildingObservable
//                .map { isBuilding in
//                    ExerciseResultViewController.evaluateTemplateStatus(participation: participation, exercise: exercise, result: result, isBuilding: isBuilding)
//                }
//                .publisher
//                .replaceError(with: .NoResult)
//                .receive(on: DispatchQueue.main)
//                .assign(to: &$templateStatus)

        templateStatus = ExerciseResultViewController.evaluateTemplateStatus(participation: participation, exercise: exercise, result: result, isBuilding: isBuilding)
    }

    private static func evaluateTemplateStatus(
            participation: Participation,
            exercise: Exercise,
            result: Result?,
            isBuilding: Bool
    ) -> ResultTemplateStatus {
        let now = Date()

        switch exercise {
        case .Modeling, .Text, .FileUpload:
            let inDueTime = participation.isInDueTime(associatedExercise: exercise)
            let dueDate = exercise.baseExercise.getDueDate(participation: participation)
            let assessmentDueDate = exercise.baseExercise.assessmentDueDate

            if inDueTime && result?.score != nil {
                // Submission is in due time of exercise and has a result with score
                if assessmentDueDate == nil || assessmentDueDate! < now {
                    return ResultTemplateStatus.HasResult(result: result!)
                } else {
                    // the assessment period is still active
                    return ResultTemplateStatus.SubmittedWaitingForGrading
                }
            } else if inDueTime {
                // Submission is in due time of exercise and doesn't have a result with score.
                if dueDate == nil || dueDate! >= now {
                    return ResultTemplateStatus.Submitted
                } else if (assessmentDueDate == nil || assessmentDueDate! >= now) {
                    // the due date is in the future (or there is none) => the exercise is still ongoing
                    return ResultTemplateStatus.SubmittedWaitingForGrading
                } else {
                    // the due date is over, further submissions are no longer possible, no result after assessment due date
                    // TODO why is this distinct from the case above? The submission can still be graded and often is.
                    return ResultTemplateStatus.NoResult
                }
            }
        case .Programming, .Quiz:
            if isBuilding {
                return .IsBuilding
            } else if result?.score != nil {
                return .HasResult(result: result!)
            } else {
                return .NoResult
            }
        default:
            return .NoResult
        }
        return .NoResult
    }
}

public struct ExerciseResultView: View {

    private let exercise: Exercise
    private let participation: Participation
    private let result: Result?
    private let showUngradedResults: Bool
    private let personal: Bool

    @StateObject private var viewController: ExerciseResultViewController

    public init(exercise: Exercise, participation: Participation, result: Result?, showUngradedResults: Bool, personal: Bool) {
        self.exercise = exercise
        self.participation = participation
        self.result = result
        self.showUngradedResults = showUngradedResults
        self.personal = personal

        let chosenResult = result ?? (participation.baseParticipation.results?.max { a, b in
            (a.completionDate ?? Date(timeIntervalSince1970: 0)) < (b.completionDate ?? Date(timeIntervalSince1970: 0))
        })

        _viewController = StateObject(
                wrappedValue: ExerciseResultViewController(
                        participation: participation,
                        exercise: exercise,
                        personal: personal,
                        showUngradedResults: showUngradedResults,
                        result: chosenResult
                )
        )

    }

    public var body: some View {
        switch viewController.templateStatus {
        case .IsBuilding: StatusIsBuildingView()
        case .NoResult:
            if showUngradedResults {
                TextStatusView(text: NSLocalizedString("exercise_result_no_result", comment: ""), textColor: nil)
            } else {
                TextStatusView(text: NSLocalizedString("exercise_result_no_graded_result", comment: ""), textColor: nil)
            }
        case .HasResult(result: let result): StatusHasResultView(result: result, isLate: false)
        case .Submitted: TextStatusView(text: NSLocalizedString("exercise_result_submitted", comment: ""), textColor: nil)
        case .SubmittedWaitingForGrading: TextStatusView(text: NSLocalizedString("exercise_result_submitted_waiting_for_grading", comment: ""), textColor: nil)
        case .LateNoFeedback: TextStatusView(text: NSLocalizedString("exercise_result_late_submission", comment: ""), textColor: nil)
        case .Late(result: let result): StatusHasResultView(result: result, isLate: true)
        case .Missing: EmptyView()
        }
    }
}

private struct StatusIsBuildingView: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()

            Text("exercise_result_is_building")
                    .font(statusFont)
        }
    }
}

private struct StatusHasResultView: View {

    private let icon: String
    private let textAndIconColor: Color
    private let text: String

    init(result: Result, isLate: Bool) {
        let resultScore = result.score ?? 0.0

        if resultScore < MIN_SCORE_GREEN {
            icon = "x.circle"
        } else {
            icon = "checkmark.circle"
        }


        if resultScore >= MIN_SCORE_GREEN {
            textAndIconColor = colorResultSuccess
        } else if resultScore >= MIN_SCORE_ORANGE {
            textAndIconColor = colorResultMedium
        } else {
            textAndIconColor = colorResulBad
        }

        if isLate {
            text = "TODO: LATE"
        } else {
            text = "TODO: Result"
        }
    }

    var body: some View {
        IconTextStatus(iconName: icon, text: text, iconColor: textAndIconColor, textColor: textAndIconColor)
    }
}

private struct TextStatusView: View {

    let text: String
    let textColor: Color?
    let font: Font = statusFont

    var body: some View {
        Text(text)
                .font(font)
                .foregroundColor(textColor)
    }
}

private struct IconTextStatus: View {

    let iconName: String
    let text: String
    let iconColor: Color
    let textColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(verbatim: text)
                    .font(statusFont)
                    .foregroundColor(textColor)

            Image(systemName: iconName)
                    .frame(height: .infinity)
                    .aspectRatio(1, contentMode: ContentMode.fit)
                    .foregroundColor(iconColor)
        }
    }
}
