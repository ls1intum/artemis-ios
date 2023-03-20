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

    var isUninitialized: Bool {
        switch exercise {
        case .quiz(let quiz):
            return quiz.isUninitialized
        default:
            return (exercise.baseExercise.dueDate ?? .now) > .now
            && studentParticipation == nil
        }
    }

    var studentParticipation: StudentParticipation? {
        exercise.getSpecificStudentParticipation(testRun: false)
    }

    var exerciseMissedDeadline: Bool {
        return (exercise.baseExercise.dueDate ?? .now) < .now
        && studentParticipation == nil
    }

    var text: String {
        if exercise.baseExercise.teamMode ?? false,
           exercise.baseExercise.studentAssignedTeamIdComputed ?? false,
           exercise.baseExercise.studentAssignedTeamId == nil {
            return R.string.localizable.userNotAssignedToTeam()
        }
        if isUninitialized {
            return R.string.localizable.userNotStartedExercise()
        }
        if exerciseMissedDeadline {
            return R.string.localizable.exerciseMissedDeadline()
        }
        return "You have missed the Deadline!"
    }

    var body: some View {
        Text(text)
            .foregroundColor(Color.Artemis.secondaryLabel)
    }
}
