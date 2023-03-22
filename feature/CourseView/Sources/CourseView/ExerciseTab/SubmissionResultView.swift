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

    var templateStatus: ResultTemplateStatus {
        guard let result else { return .noResult }

        return result.getTemplateStatus(for: exercise,
                                        and: participation,
                                        isBuilding: isBuilding,
                                        missingResultInfo: missingResultInfo)
    }

    var body: some View {
        HStack {
            templateStatus.getIcon(for: result)
            Text("TODO")
        }
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
}
