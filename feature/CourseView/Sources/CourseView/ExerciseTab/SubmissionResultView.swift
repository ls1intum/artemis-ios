//
//  SubmissionResultView.swift
//  
//
//  Created by Sven Andabaka on 21.03.23.
//

import SwiftUI
import SharedModels

struct SubmissionResultView: View {

    let exercise: Exercise
    let participation: BaseParticipation
    let result: Result?
    let missingResultInfo: MissingResultInformation
    let isBuilding: Bool
    let showUngradedResult = false

    var templateStatus: ResultTemplateStatus {
        guard let result else { return .noResult }

        return result.getTemplateStatus(for: exercise,
                                        and: participation,
                                        isBuilding: isBuilding,
                                        missingResultInfo: missingResultInfo)
    }

    var text: String {
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
            return R.string.localizable.exerciseLateFeedback()
        case .hasResult:
            return "TODO"
        default:
            return showUngradedResult ? R.string.localizable.noResult() : R.string.localizable.noGradedResult()
        }
    }

    var body: some View {
        HStack {
            if let icon = templateStatus.getIcon(for: result) {
                icon
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: .extraSmallImage)
            }
            Text(text)
        }.foregroundColor(templateStatus.getColor(for: result))
    }
}

extension ResultTemplateStatus {

    // swiftlint:disable cyclomatic_complexity
    private func getIconName(result: Result?) -> String? {
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
            if result.isResultPreliminary {
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

    func getIcon(for result: Result?) -> Image? {
        guard let iconName = getIconName(result: result) else {
            return nil
        }
        return Image(iconName, bundle: .module)
    }

    func getColor(for result: Result?) -> Color {
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
            if result.isResultPreliminary {
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
