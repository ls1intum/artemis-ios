//
//  QuizTrainingViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.06.26.
//

import APIClient
import Common
import Foundation
import SharedModels

@Observable
class QuizTrainingViewModel {
    let courseId: Int

    var questions: DataState<[DTO.QuizQuestionTraining]> = .loading

    var lastSubmissionResult: DataState<DTO.SubmittedAnswerAfterEvaluation> = .loading
    var hasSubmitted: Bool {
        if case .done = lastSubmissionResult {
            return true
        } else {
            return false
        }
    }

    var currentScore: (reached: Double, total: Double)? {
        let total = switch questions.value?.first?.quizQuestionWithSolutionDTO {
        case .dragAndDrop(let question): question.points
        case .multipleChoice(let question): question.points
        case .shortAnswer(let question): question.points
        default: 0.0
        }
        let reached = lastSubmissionResult.value?.scoreInPoints
        if let reached, let total {
            return (reached, total)
        }
        return nil
    }

    init(courseId: Int) {
        self.courseId = courseId
    }

    func loadQuestions() async {
        questions = await APIClient().call { client in
            try await client
                .getQuizQuestionsForPractice(path: .init(courseId: Int64(courseId)),
                                             query: .init(isNewSession: true),
                                             body: .json([]))
                .ok.body.json
        }
    }

    func goToNextQuestion() {
        questions.value?.removeFirst()
        lastSubmissionResult = .loading
    }

    func submitAnswer(questionId: Int64, isRated: Bool, answer: QuizTrainingAnswer) async {
        lastSubmissionResult = await APIClient().call { client in
            try await client
                .submitForTraining(path: .init(courseId: Int64(courseId),
                                               trainingQuestionId: questionId),
                                   query: .init(isRated: isRated),
                                   body: .json(answer))
                .ok.body.json
        }
    }
}
