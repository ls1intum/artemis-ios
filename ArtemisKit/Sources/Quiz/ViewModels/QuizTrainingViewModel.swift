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
}
