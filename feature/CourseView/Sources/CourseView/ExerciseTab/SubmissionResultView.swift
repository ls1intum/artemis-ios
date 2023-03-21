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
    let participation: Participation
    let result: Result
    let missingResultInfo: MissingResultInformation
    let isBuilding: Bool

    var templateStatus: ResultTemplateStatus {
        result.getTemplateStatus(for: exercise,
                                 and: participation,
                                 isBuilding: isBuilding,
                                 missingResultInfo: missingResultInfo)
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

extension ResultTemplateStatus {

    private func getIconName(result: Result?) -> String {
        switch self {
        case .isBuilding:
            return "circle-notch-solid"
        case .hasResult:
            guard let result else {
                return "circle-question-solid"
            }
            if result.isBuildFailedAndResultIsAutomatic {
                return "circle-xmark-solid"
            }
            
            return "circle-question-solid"
            
//        case .noResult:
//            <#code#>
//        case .submitted:
//            <#code#>
//        case .submittedWaitingForGrading:
//            <#code#>
//        case .lateNoFeedback:
//            <#code#>
//        case .late:
//            <#code#>
//        case .missing:
//            <#code#>
        default:
            return "circle-question-solid"
        }
    }

    func getIcon(for result: Result?) -> Image {
        return Image(getIconName(result: result), bundle: .module)
    }
}
