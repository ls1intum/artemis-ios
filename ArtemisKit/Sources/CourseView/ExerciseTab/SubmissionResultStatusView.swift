//
//  SubmissionResultStatusView.swift
//  
//
//  Created by Sven Andabaka on 20.03.23.
//

import SwiftUI
import SharedModels

struct SubmissionResultStatusView: View {

    let exercise: Exercise

    let showUngradedResults = false

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
            return exercise.baseExercise.dueDate ?? .tomorrow > .now && studentParticipation != nil && (studentParticipation?.submissions?.isEmpty ?? true)
        }
    }

    var text: [String] {
        var result: [String] = []
        if exercise.baseExercise.teamMode ?? false,
           exercise.baseExercise.studentAssignedTeamIdComputed ?? false,
           exercise.baseExercise.studentAssignedTeamId == nil {
            result.append(R.string.localizable.userNotAssignedToTeam())
        }
        if isUninitialized {
            result.append(R.string.localizable.userNotStartedExercise())
        }
        if exerciseMissedDeadline {
            result.append(R.string.localizable.exerciseMissedDeadline())
        }
        if notSubmitted {
            result.append(R.string.localizable.exerciseNotSubmitted())
        }
        if studentParticipation?.initializationState == .finished {
            result.append(R.string.localizable.userSubmitted())
        }
        if studentParticipation?.initializationState == .initialized,
           case .quiz = exercise {
            result.append(R.string.localizable.userParticipating())
        }
        if quizNotStarted {
            result.append(R.string.localizable.quizNotStarted())
        }
        return result
    }

    var result: Result? {
        // The latest result is the first rated result in the sorted array (=newest) or any result if the option is active to show ungraded results.
        if showUngradedResults {
            return studentParticipation?.results?.first
        } else {
            return studentParticipation?.results?.first(where: { $0.rated == true })
        }
    }

    var body: some View {
        if let studentParticipation,
           !(studentParticipation.results ?? []).isEmpty {
            SubmissionResultView(exercise: exercise,
                                 participation: studentParticipation,
                                 result: result,
                                 missingResultInfo: .noInformation,
                                 isBuilding: false,
                                 short: true)
        } else {
            VStack(alignment: .leading) {
                ForEach(text, id: \.self) { text in
                    Text(text)
                        .foregroundColor(Color.Artemis.secondaryLabel)
                }
            }
        }
    }
}

extension SubmissionResultStatusView {

    /// Single short status line – exactly the same decision order as the web UI.
    static func singleShortStatus(for exercise: Exercise) -> String {
        let base   = exercise.baseExercise
        let teamId = base.studentAssignedTeamId
        let teamOk = !(base.teamMode ?? false)
        || !(base.studentAssignedTeamIdComputed ?? false)
        || teamId != nil

        let participation = exercise.getSpecificStudentParticipation(testRun: false)

        let uninitialized  = (base.dueDate ?? .tomorrow) > .now && participation == nil
        let missedDueDate  = (base.dueDate ?? .tomorrow) < .now && participation == nil

        if !teamOk {
            return R.string.localizable.userNotAssignedToTeamShort()
        } else if uninitialized {
            return R.string.localizable.userNotStartedExerciseShort()
        } else if missedDueDate {
            return R.string.localizable.exerciseMissedDeadlineShort()
        } else if participation?.initializationState == .finished {
            return R.string.localizable.userSubmittedShort()
        } else if participation?.initializationState == .initialized,
                  case .quiz = exercise {
            return R.string.localizable.userParticipatingShort()
        } else if case .quiz(let quiz) = exercise, quiz.notStarted {
            return R.string.localizable.quizNotStartedShort()
        } else {
            return "–"
        }
    }
}
