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
            return switch answer {
            case .dragAndDrop(let answer): answer.scoreInPoints
            case .multipleChoice(let answer): answer.scoreInPoints
            case .shortAnswer(let answer): answer.scoreInPoints
            }
        } else if case .done(let answers) = lastSubmissionResults {
            let answer = answers.first(where: {
                let question = switch $0 {
                case .dragAndDrop(let answer): answer.quizQuestion
                case .multipleChoice(let answer): answer.quizQuestion
                case .shortAnswer(let answer): answer.quizQuestion
                }
                return question?.id == questionId
            })
            return switch answer {
            case .dragAndDrop(let answer): answer.scoreInPoints
            case .multipleChoice(let answer): answer.scoreInPoints
            case .shortAnswer(let answer): answer.scoreInPoints
            case .none: nil
            }
        }
        return nil
    }
}
