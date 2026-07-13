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
    var submissionSuccessful: Bool?

    var selectedQuestion: Int?

    var answers = [DTO.SubmittedAnswerFromLiveClient]()

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

    var questionCount: Int {
        switch participation.value {
        case .StudentQuizParticipationWithQuestions(let p): p.exercise?.quizQuestions?.count ?? 0
        case .StudentQuizParticipationWithSolutions(let p): p.exercise?.quizQuestions?.count ?? 0
        default: 0
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

    func saveAnswer(_ answer: DTO.SubmittedAnswerFromLiveClient) {
        if let existingIndex = answers.firstIndex(where: {
            switch ($0, answer) {
            case (.dragAndDrop(let dnd), .dragAndDrop(let new)):
                return dnd.quizQuestion?.id == new.quizQuestion?.id
            case (.shortAnswer(let sa), .shortAnswer(let new)):
                return sa.quizQuestion?.id == new.quizQuestion?.id
            case (.multipleChoice(let mc), .multipleChoice(let new)):
                return mc.quizQuestion?.id == new.quizQuestion?.id
            default: return false
            }
        }) {
            answers[existingIndex] = answer
        } else {
            answers.append(answer)
        }
    }

    func nextQuestion() {
        if let selectedQuestion {
            self.selectedQuestion = (selectedQuestion + 1) % questionCount
        }
    }

    func previousQuestion() {
        if let selectedQuestion {
            self.selectedQuestion = (selectedQuestion - 1 + questionCount) % questionCount
        }
    }

    func submit() async {
        if isLiveQuiz {
            await submitAnswers(submit: true)
        } else {
            await submitAnswersForPractice()
        }
    }

    private func submitAnswers(submit: Bool) async {
        let submission = await APIClient().call { client in
            try await client
                .saveOrSubmitForLiveMode(path: .init(exerciseId: Int64(exercise.id)),
                                         query: .init(submit: submit),
                                         body: .json(.init(submittedAnswers: answers)))
                .ok.body.json
        }
        switch submission {
        case .done(let response):
            if response.submitted == true {
                submissionSuccessful = true
            }
        default: submissionSuccessful = false
        }
    }

    private func submitAnswersForPractice() async {
        let studentAnswers: [DTO.SubmittedAnswerFromStudent] = answers.map {
            switch $0 {
            case .dragAndDrop(let dnd):
                let mappings = (dnd.mappings ?? []).map {
                    DTO.DragAndDropMappingReEvaluate(dragItemId: $0.dragItem?.id ?? 0,
                                                     dropLocationId: $0.dropLocation?.id ?? 0)
                }
                return .dragAndDrop(.init(questionId: dnd.quizQuestion?.id ?? 0,
                                          mappings: mappings,
                                          _type: .dragAndDrop))
            case .multipleChoice(let mc):
                let selected = (mc.selectedOptions ?? []).compactMap(\.id)
                return .multipleChoice(.init(questionId: mc.quizQuestion?.id ?? 0,
                                             selectedOptions: selected,
                                             _type: .multipleChoice))
            case .shortAnswer(let sa):
                let submitted = (sa.submittedTexts ?? []).map {
                    DTO.ShortAnswerSubmittedTextFromStudent(text: $0.text ?? "", spotId: $0.spot?.id ?? 0)
                }
                return .shortAnswer(.init(questionId: sa.quizQuestion?.id ?? 0,
                                          submittedTexts: submitted,
                                          _type: .shortAnswer))
            }
        }
        let submission = await APIClient().call { client in
            try await client
                .submitForPractice(path: .init(exerciseId: Int64(exercise.id)),
                                   body: .json(.init(submittedAnswers: studentAnswers)))
                .ok.body.json
        }

        switch submission {
        case .done(let response): submissionSuccessful = response.successful ?? false
        default: submissionSuccessful = false
        }
    }
}
