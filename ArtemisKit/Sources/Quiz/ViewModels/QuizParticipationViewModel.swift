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
class QuizParticipationViewModel: QuizViewModel {
    let exercise: QuizExercise
    let courseId: Int

    var participation: DataState<DTO.StudentQuizParticipation> = .loading
    var loadingQuizStart = false
    var waitingForResults = false
    var submissionSuccessful: Bool?
    var batchStartError: String?
    let isLiveQuiz: Bool
    var savedResults = true
    var autoSaveTimer: Timer?

    var selectedQuestion = 0

    var answers = [DTO.SubmittedAnswerFromLiveClient]()

    init(exercise: QuizExercise, courseId: Int) {
        self.exercise = exercise
        self.courseId = courseId
        isLiveQuiz = exercise.canStartLiveQuiz || exercise.canResumeQuiz && !exercise.canStartPractice
    }

    private let stompClient = ArtemisStompClient.shared
    private var syncQuizTask: Task<Void, Never>?
    private var waitForSolutionsTask: Task<Void, Never>?

    var questionCount: Int {
        switch participation.value {
        case .liveQuiz(let p): p.exercise?.quizQuestions?.count ?? 0
        case .afterQuizEnd(let p): p.exercise?.quizQuestions?.count ?? 0
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
        loadingQuizStart = true
        participation = await APIClient().call { client in
            try await client.startParticipation(path: .init(exerciseId: Int64(exercise.id)))
                .ok.body.json
        }
        loadingQuizStart = false
    }

    func joinBatch(password: String? = nil) async {
        let response = await APIClient().call { client in
            try await client.joinBatch(path: .init(quizExerciseId: Int64(exercise.id)),
                                       body: .json(.init(password: password)))
            .ok.body.json
        }

        switch response {
        case .done(let response):
            startWaitingForBatchStart(batchId: response.id)
            if password == nil {
                await startParticipation()
            }
        case .failure(let error):
            batchStartError = error.localizedDescription
        default: break
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

    func startWaitingForBatchStart(batchId: Int64?) {
        guard syncQuizTask == nil, let batchId else { return }
        syncQuizTask = Task {
            let stream = stompClient.subscribe(to: "/topic/courses/\(courseId)/quizExercises/\(batchId)")

            for await message in stream {
                print("Received Socket update")
                if let decoded = JSONDecoder.getTypeFromSocketMessage(type: DTO.StudentQuizParticipation.self, message: message) {
                    print("Socket update: \(decoded)")
                    participation = .done(response: decoded)
                } else {
                    await startParticipation()
                }
            }
        }
    }

    func startWaitingForSolutions() {
        guard waitForSolutionsTask == nil else { return }
        waitForSolutionsTask = Task {
            let stream = stompClient.subscribe(to: "/user/topic/exercise/\(exercise.id)/participation")

            for await message in stream {
                print("Received Socket update")
                if let decoded = JSONDecoder.getTypeFromSocketMessage(type: DTO.StudentQuizParticipation.self, message: message) {
                    participation = .done(response: decoded)
                    switch decoded {
                    case .afterQuizEnd:
                        waitingForResults = false
                        waitForSolutionsTask?.cancel()
                        waitForSolutionsTask = nil
                    default: break
                    }
                }
            }
        }
    }

    func startAutoSave() {
        guard isLiveQuiz else { return }
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] timer in
            Task(priority: .utility) {
                guard let self else {
                    timer.invalidate()
                    return
                }
                await self.submitAnswers(submit: false)
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
            if answers[existingIndex] != answer {
                savedResults = false
            }
            answers[existingIndex] = answer
        } else {
            savedResults = false
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
            autoSaveTimer?.invalidate()
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
            savedResults = true
            if response.submitted == true {
                submissionSuccessful = true
                waitingForResults = true
                startWaitingForSolutions()
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
        case .done(let result):
            if let answers = result.submission?.submittedAnswers {
                lastSubmissionResults = .done(response: answers)
            }
            submissionSuccessful = true
        default: submissionSuccessful = false
        }
    }
}
