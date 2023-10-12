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
            Color.green
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
