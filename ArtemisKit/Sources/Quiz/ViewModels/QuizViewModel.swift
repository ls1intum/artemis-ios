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

    func score(questionId: Int64?) -> Double? {
        if case .done(let answer) = lastSubmissionResult {
            return answer.scoreInPoints
        } else if case .done(let answers) = lastSubmissionResults {
            return answers.first(where: { $0.quizQuestion?.id == questionId })?.scoreInPoints
        }
        return nil
    }
}
