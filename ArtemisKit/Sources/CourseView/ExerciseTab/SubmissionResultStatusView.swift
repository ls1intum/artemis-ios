//
//  SubmissionResultStatusView.swift
//
//
//  Created by Sven Andabaka on 20.03.23.
//

import SwiftUI
import SharedModels

struct SubmissionResultStatusView: View {

    enum TextLength {
        case full, short
    }

    let exercise: Exercise

    var length: TextLength = .full

    var isUninitialized: Bool {
        switch exercise {
        case .quiz(let quiz):
            return quiz.isUninitialized
        default:
            return (exercise.baseExercise.dueDate ?? .tomorrow) > .now
            && studentParticipation == nil
        }
    }

    var quizNotStarted: Bool {
        switch exercise {
        case .quiz(let quiz):
            return quiz.notStarted
        default:
            return false
        }
    }

    var studentParticipation: StudentParticipation? {
        exercise.getSpecificStudentParticipation(testRun: false)
    }

    var exerciseMissedDeadline: Bool {
        return (exercise.baseExercise.dueDate ?? .tomorrow) < .now
        && studentParticipation == nil
    }

    var notSubmitted: Bool {
        switch exercise {
        case .quiz:
            return false
        default:
            let afterDueDate = (exercise.baseExercise.dueDate ?? .distantFuture) < .now
            let hasParticipation = studentParticipation != nil
            let hasNoSubmissions = studentParticipation?.submissions?.isEmpty ?? true

            return afterDueDate && hasParticipation && hasNoSubmissions
        }
    }

    var text: [String] {
        var result: [String] = []
        if exercise.baseExercise.teamMode ?? false,
           exercise.baseExercise.studentAssignedTeamIdComputed ?? false,
           exercise.baseExercise.studentAssignedTeamId == nil {
            result.append(length == .full
                          ? R.string.localizable.userNotAssignedToTeam()
                          : R.string.localizable.userNotAssignedToTeamShort())
        }
        if isUninitialized {
            result.append( length == .full
                           ? R.string.localizable.userNotStartedExercise()
                           : R.string.localizable.notYetStarted())
        }
        if exerciseMissedDeadline {
            result.append(length == .full
                          ? R.string.localizable.exerciseMissedDeadline()
                          : R.string.localizable.exerciseMissedDeadlineShort())
        }
        if notSubmitted {
            result.append(length == .full
                          ? R.string.localizable.exerciseNotSubmitted()
                          : "–")
        }
        if studentParticipation?.initializationState == .finished {
            result.append(length == .full
                          ? R.string.localizable.userSubmitted()
                          : R.string.localizable.userSubmittedShort())
        }
        if studentParticipation?.initializationState == .initialized,
           case .quiz = exercise {
            result.append(length == .full
                          ? R.string.localizable.userParticipating()
                          : R.string.localizable.userParticipatingShort())
        }
        if quizNotStarted {
            result.append(length == .full
                          ? R.string.localizable.quizNotStarted()
                          : R.string.localizable.notYetStarted())
        }
        return length == .full ? result : (result.first.map { [$0] } ?? [])
    }

    var result: Result? {
        let submissionResults: [Result] = studentParticipation?.submissions?
            .flatMap { submission in
                (submission.baseSubmission.results ?? []).compactMap { $0 }
            }
            .filter { $0.rated == true } ?? []

        let latestFromSubmissions = submissionResults
            .max(by: { ($0.completionDate ?? .distantPast) < ($1.completionDate ?? .distantPast) })

        return latestFromSubmissions
    }

    var body: some View {
        if let result, let participation = studentParticipation {
            SubmissionResultView(exercise: exercise,
                                 participation: participation,
                                 result: result,
                                 missingResultInfo: .noInformation,
                                 isBuilding: false,
                                 short: true)
        } else {
            VStack(alignment: .leading) {
                ForEach(text, id: \.self) { line in
                    Text(line)
                        .foregroundColor(Color.Artemis.secondaryLabel)
                }
            }
        }
    }
}
