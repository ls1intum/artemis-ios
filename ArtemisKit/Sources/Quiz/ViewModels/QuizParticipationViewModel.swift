//
//  QuizParticipationViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.07.26.
//

import APIClient
import Common
import Foundation
import SharedModels

@Observable
class QuizParticipationViewModel {
    let exercise: QuizExercise

    var participation: DataState<DTO.StudentQuizParticipation> = .loading

    init(exercise: QuizExercise) {
        self.exercise = exercise
    }

    func startParticipation() async {
        participation = await APIClient().call { client in
            try await client.startParticipation(path: .init(exerciseId: Int64(exercise.id)))
                .ok.body.json
        }
    }
}
