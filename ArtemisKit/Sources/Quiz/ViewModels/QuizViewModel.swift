//
//  QuizViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 16.07.26.
//

import Common
import Foundation
import SharedModels

@Observable
class QuizViewModel {
    var lastSubmissionResults: DataState<[DTO.SubmittedAnswerAfterEvaluation]> = .loading
    var lastSubmissionResult: DataState<DTO.SubmittedAnswerAfterEvaluation> = .loading

    var hasSubmitted: Bool {
        if case .done = lastSubmissionResult {
            return true
        } else if case .done = lastSubmissionResults {
            return true
        } else {
            return false
        }
    }
}
