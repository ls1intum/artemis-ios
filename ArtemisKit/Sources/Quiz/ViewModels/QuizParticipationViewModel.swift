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

    private let stompClient = ArtemisStompClient.shared
    private var syncQuizTask: Task<Void, Never>?

    var isLiveQuiz: Bool {
        switch participation.value {
        case .StudentQuizParticipationWithQuestions(let quiz):
            quiz.exercise?.quizEnded != true
        case .StudentQuizParticipationWithSolutions(let quiz):
            quiz.exercise?.quizEnded != true
        case .StudentQuizParticipationWithoutQuestions(let quiz):
            quiz.exercise?.quizEnded != true
        default:
            false
        }
    }

    func startParticipation() async {
        participation = await APIClient().call { client in
            try await client.startParticipation(path: .init(exerciseId: Int64(exercise.id)))
                .ok.body.json
        }
    }

    func startWaitingForQuizStart() {
        guard syncQuizTask == nil else { return }
        syncQuizTask = Task {
            let stream = stompClient.subscribe(to: "/topic/courses/\(exercise.course?.id ?? 0)/quizExercises")

            for await message in stream {
                print("Received Socket update")
                if let data = message as? Data,
                   let decoded = try? JSONDecoder().decode(DTO.StudentQuizParticipation.self, from: data) {
                    print("Socket update: \(decoded)")
                    participation = .done(response: decoded)
                }
            }
        }
    }

    func onSyncDisappear() {
        syncQuizTask?.cancel()
        syncQuizTask = nil
    }
}
