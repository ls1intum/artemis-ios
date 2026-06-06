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
