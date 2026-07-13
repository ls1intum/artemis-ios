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
    let courseId: Int

    var participation: DataState<DTO.StudentQuizParticipation> = .loading
    var submissionSuccessful: Bool?
    var batchStartError: String?
    let isLiveQuiz: Bool

    var selectedQuestion = 0

    var answers = [DTO.SubmittedAnswerFromLiveClient]()

    init(exercise: QuizExercise, courseId: Int) {
        self.exercise = exercise
        self.courseId = courseId
        isLiveQuiz = exercise.canStartLiveQuiz
    }

    private let stompClient = ArtemisStompClient.shared
    private var syncQuizTask: Task<Void, Never>?

    var questionCount: Int {
        switch participation.value {
        case .StudentQuizParticipationWithQuestions(let p): p.exercise?.quizQuestions?.count ?? 0
        case .StudentQuizParticipationWithSolutions(let p): p.exercise?.quizQuestions?.count ?? 0
        default: 0
        }
    }

    func getAnswer(for questionId: Int64?) -> DTO.SubmittedAnswerFromLiveClient? {
        answers.first {
            switch $0 {
            case let .dragAndDrop(dnd):
                return dnd.quizQuestion?.id == questionId
            case let .shortAnswer(sa):
                return sa.quizQuestion?.id == questionId
            case let .multipleChoice(mc):
                return mc.quizQuestion?.id == questionId
            }
        }
    }

    func startParticipation() async {
        participation = await APIClient().call { client in
            try await client.startParticipation(path: .init(exerciseId: Int64(exercise.id)))
                .ok.body.json
        }
    }

    func joinBatch(password: String = "") async {
        struct JoinQuizRequest: APIRequest {
            typealias Response = JoinQuizResponse

            let exerciseId: Int
            let password: String

            var method: HTTPMethod { .post }
            var resourceName: String { "/api/quiz/quiz-exercises/\(exerciseId)/join" }
        }

        struct JoinQuizResponse: Codable {
            let id: Int
        }

        let response = await APIClient().sendRequest(JoinQuizRequest(exerciseId: exercise.id, password: password))

        switch response {
        case .success(let (res, _)):
            startWaitingForBatchStart(batchId: res.id)
        case .failure(let error):
            batchStartError = error.localizedDescription
        }
    }

    func startWaitingForQuizStart() {
        guard syncQuizTask == nil else { return }
        syncQuizTask = Task {
            let stream = stompClient.subscribe(to: "/topic/courses/\(courseId)/quizExercises")

            for await message in stream {
                print("Received Socket update")
                if let data = message as? Data,
                   let decoded = try? JSONDecoder().decode(DTO.StudentQuizParticipation.self, from: data) {
                    print("Socket update: \(decoded)")
                    participation = .done(response: decoded)
                } else {
                    await startParticipation()
                }
            }
        }
    }

    func startWaitingForBatchStart(batchId: Int) {
        guard syncQuizTask == nil else { return }
        syncQuizTask = Task {
            let stream = stompClient.subscribe(to: "/topic/courses/\(courseId)/quizExercises/\(batchId)")

            for await message in stream {
                print("Received Socket update")
                if let data = message as? Data,
                   let decoded = try? JSONDecoder().decode(DTO.StudentQuizParticipation.self, from: data) {
                    print("Socket update: \(decoded)")
                    participation = .done(response: decoded)
                } else {
                    await startParticipation()
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
            case let (.dragAndDrop(dnd), .dragAndDrop(new)):
                return dnd.quizQuestion?.id == new.quizQuestion?.id
            case let (.shortAnswer(sa), .shortAnswer(new)):
                return sa.quizQuestion?.id == new.quizQuestion?.id
            case let (.multipleChoice(mc), .multipleChoice(new)):
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
        selectedQuestion = (selectedQuestion + 1) % questionCount
    }

    func previousQuestion() {
        selectedQuestion = (selectedQuestion - 1 + questionCount) % questionCount
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
        let studentAnswers: [DTO.SubmittedAnswerFromStudent] = answers.compactMap {
            $0.asAnswerFromStudent()
        }

        let submission = await APIClient().call { client in
            try await client
                .submitForPractice(path: .init(exerciseId: Int64(exercise.id)),
                                   body: .json(.init(submittedAnswers: studentAnswers)))
                .ok.body.json
        }

        switch submission {
        case .done: submissionSuccessful = true
        default: submissionSuccessful = false
        }
    }
}
