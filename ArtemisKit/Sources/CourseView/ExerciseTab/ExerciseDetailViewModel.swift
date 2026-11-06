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

    var showQuizParticipation = false
    var latestResultId: Int?
    var participationId: Int?

    // MARK: Web view
    var isWebViewLoading = true
    var webViewHeight = CGFloat.s

    private let exerciseService: ExerciseService
    private let userSession: UserSession
    private let reviewReader: (any ReviewReading)?
    var scorePrecision = 1

    init(
        courseId: Int,
        exerciseId: Int,
        exercise: DataState<Exercise>,
        exerciseService: ExerciseService = ExerciseServiceFactory.shared,
        userSession: UserSession = UserSessionFactory.shared,
        reviewReader: (any ReviewReading)? = nil
    ) {
        self.courseId = courseId
        self.exerciseId = exerciseId

        self.exercise = exercise
        self.problemStatementRendered = .loading

        self.exerciseService = exerciseService
        self.userSession = userSession
        self.reviewReader = reviewReader
    }

    func loadExercise() async {
        if let exercise = exercise.value {
            if case .quiz(let quiz) = exercise, quiz.quizMode == nil {
                // Not enough data available to open quiz -> load new
                await refreshExercise()
            } else {
                setParticipationAndResultId(from: exercise)
            }
        } else {
            await refreshExercise()
        }
    }

    func loadReviewMetadata() async {
        let transport = ReviewSession.current().map { ReviewTransport(captured: $0) }
        defer { transport?.invalidate() }
        guard let reader = reviewReader ?? transport else { return }
        struct Details: Decodable { let exercise: ReviewExercise }
        guard let details = try? await reader.read(Details.self, path: "/api/exercise/exercises/\(exerciseId)/details"),
              reader.isCurrent, details.exercise.id == exerciseId,
              details.exercise.course?.id == courseId else { return }
        scorePrecision = min(10, max(0, details.exercise.course?.accuracyOfScores ?? 1))
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

        guard let resultScore = latestRatedResult?.score else { return "—" }
        return ReviewScore.points(score: resultScore, maximum: exercise.value?.baseExercise.maxPoints, precision: scorePrecision)?.clean ?? "—"
    }

    var reviewReferences: [ReviewReference] {
        guard let exercise = exercise.value else { return [] }
        return (exercise.baseExercise.studentParticipations ?? []).flatMap { participation -> [ReviewReference] in
            let source = participation.baseParticipation
            return (source.submissions ?? []).flatMap { submission -> [ReviewReference] in
                let work = submission.baseSubmission
                guard let submissionID = work.id else { return [] }
                return (work.results ?? []).compactMap { result -> ReviewReference? in
                    guard let result, let resultID = result.id else { return nil }
                    return ReviewReference(courseID: courseId, exerciseID: exerciseId, participationID: source.id,
                                           submissionID: submissionID, resultID: resultID, submissionDate: work.submissionDate,
                                           completionDate: result.completionDate, rated: result.rated)
                }
            }
        }.sorted { ($0.completionDate ?? .distantPast) > ($1.completionDate ?? .distantPast) }
    }

    var isFeedbackButtonVisible: Bool {
        switch exercise.value {
        case .fileUpload, .programming, .text, .modeling, .quiz:
            return true
        default:
            return false
        }
    }

    var isExerciseParticipationAvailable: Bool {
        switch exercise.value {
        case .quiz: true
        default: false
        }
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
