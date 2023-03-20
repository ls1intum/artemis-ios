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
            return (exercise.baseExercise.dueDate ?? .yesterday) > .now
            && studentParticipation == nil
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
            // check
            return exercise.baseExercise.dueDate ?? .tomorrow > .now && studentParticipation != nil && (studentParticipation?.submissions?.isEmpty ?? true)
//            return !afterDueDate && !!this.studentParticipation && !this.studentParticipation.submissions?.length;
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
        return result
    }

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(text, id: \.self) { text in
                Text(text)
                    .foregroundColor(Color.Artemis.secondaryLabel)
            }
        }
    }
}
