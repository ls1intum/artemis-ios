//
//  ExerciseDetailViewModel.swift
//
//
//  Created by Nityananda Zbil on 14.06.24.
//

import Common
import Foundation
import SharedModels
import SharedServices
import UserStore

@Observable
final class ExerciseDetailViewModel {
    let courseId: Int
    let exerciseId: Int

    var exercise: DataState<Exercise>
    var problemStatementRendered: DataState<String> = .loading
    var problemStatementRenderedDark: DataState<String> = .loading
    var channel: DataState<Channel> = .loading

    var isFeedbackPresented = false
    var latestResultId: Int?
    var participationId: Int?

    // MARK: Web view
    var isWebViewLoading = true
    var webViewHeight = CGFloat.s

    private let exerciseService: ExerciseService
    private let userSession: UserSession

    init(
        courseId: Int,
        exerciseId: Int,
        exercise: DataState<Exercise>,
        exerciseService: ExerciseService = ExerciseServiceFactory.shared,
        userSession: UserSession = UserSessionFactory.shared
    ) {
        self.courseId = courseId
        self.exerciseId = exerciseId

        self.exercise = exercise
        self.problemStatementRendered = .loading

        self.exerciseService = exerciseService
        self.userSession = userSession
    }

    func loadExercise() async {
        if let exercise = exercise.value {
            setParticipationAndResultId(from: exercise)
        } else {
            await refreshExercise()
        }
    }

    func refreshExercise() async {
        exercise = await exerciseService.getExercise(exerciseId: exerciseId)
        if let exercise = exercise.value {
            setParticipationAndResultId(from: exercise)
        }
    }

    func loadRenderedProblemStatement(darkMode: Bool) async {
        if exercise.value?.baseExercise.problemStatement == nil {
            await refreshExercise()
        }
        guard let problemStatement = exercise.value?.baseExercise.problemStatement else {
            problemStatementRendered = .done(response: "") // Empty problem statement
            return
        }

        let problemService = ProblemStatementServiceFactory.shared
        let result = await problemService.getRenderedProblemStatement(for: problemStatement, darkMode: darkMode)
        if darkMode {
            problemStatementRenderedDark = result
        } else {
            problemStatementRendered = result
        }
    }

    func loadAssociatedChannel() async {
        channel = await ExerciseChannelServiceFactory.shared.getAssociatedChannel(for: exerciseId, in: courseId)
    }

    private func setParticipationAndResultId(from exercise: Exercise) {
        isWebViewLoading = true

        let participation = exercise.getSpecificStudentParticipation(testRun: false)
        participationId = participation?.id
        // The latest result is the first rated result in the sorted array (=newest)
        if let latestResultId = exercise.baseExercise.latestRatedResult?.id {
            self.latestResultId = latestResultId
        }
    }
}

extension ExerciseDetailViewModel {
    var score: String {
        let latestRatedResult = exercise.value?.baseExercise.latestRatedResult

        let resultScore = latestRatedResult?.score ?? 0
        let maxPoints = exercise.value?.baseExercise.maxPoints ?? 0
        let finalScore = round(resultScore * maxPoints / 10) / 10

        return finalScore.clean
    }

    var isFeedbackButtonVisible: Bool {
        switch exercise.value {
        case .fileUpload, .programming, .text:
            return true
        default:
            return false
        }
    }

    var isExerciseParticipationAvailable: Bool {
        // TODO: Re-enable when fixed
//        switch exercise.value {
//        case .modeling, .text:
//            return true
//        default:
//            return false
//        }
        false
    }
}

extension BaseExercise {
    var latestRatedResult: Result? {
        guard let participations = studentParticipations else { return nil }

        var allRatedResults: [Result] = []

        for participation in participations {
            let submissions = participation.baseParticipation.submissions ?? []
            for submission in submissions {
                let results = submission.baseSubmission.results ?? []
                let ratedResults = results.compactMap { $0 }.filter { $0.rated == true }
                allRatedResults.append(contentsOf: ratedResults)
            }
        }

        return allRatedResults.max(by: {
            ($0.completionDate ?? .distantPast) < ($1.completionDate ?? .distantPast)
        })
    }
}
