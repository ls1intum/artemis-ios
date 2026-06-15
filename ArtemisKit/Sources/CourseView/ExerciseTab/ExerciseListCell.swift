//
//  ExerciseListCell.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 06.06.26.
//

import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

struct ExerciseListCell: View {
    @EnvironmentObject var navigationController: NavigationController

    let course: Course
    let exercise: Exercise

    var showAdditionalBadges: Bool {
        if let releaseDate = exercise.baseExercise.releaseDate,
           releaseDate > .now {
            return true
        }
        if let categories = exercise.baseExercise.categories, !categories.isEmpty {
            return true
        }
        return exercise.baseExercise.includedInOverallScore != .includedCompletely
    }

    var body: some View {
        NavigationLink(value: ExercisePath(exercise: exercise, coursePath: CoursePath(course: course))) {
            HStack(alignment: .top, spacing: 0) {
                if let difficulty = exercise.baseExercise.difficulty {
                    Rectangle()
                        .frame(width: .m)
                        .foregroundStyle(difficulty.color)
                        .accessibilityLabel(difficulty.description)
                }
                VStack(alignment: .leading, spacing: .m) {
                    HStack(spacing: .m) {
                        exercise.image
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: .smallImage)
                        Text(exercise.baseExercise.title ?? "")
                            .font(.title3)
                            .lineLimit(1)
                    }
                    if let dueDate = exercise.baseExercise.dueDate {
                        Text(dueDate, style: .date)
                    } else {
                        Text(R.string.localizable.noDueDate())
                    }
                    SubmissionResultStatusView(exercise: exercise)
                    if showAdditionalBadges {
                        FlowLayout(spacing: .xs) {
                                if let releaseDate = exercise.baseExercise.releaseDate,
                                   releaseDate > .now {
                                    Chip(
                                        text: R.string.localizable.notReleased(),
                                        backgroundColor: Color.Artemis.badgeWarningColor, padding: .s)
                                }
                                ForEach(exercise.baseExercise.categories ?? [], id: \.category) { category in
                                    Chip(text: category.category, backgroundColor: UIColor(hexString: category.colorCode).suColor, padding: .s)
                                }
                                // TODO: maybe add isActiveQuiz in presentationMode badge
                                if exercise.baseExercise.includedInOverallScore != .includedCompletely {
                                    Chip(
                                        text: exercise.baseExercise.includedInOverallScore.description,
                                        backgroundColor: exercise.baseExercise.includedInOverallScore.color, padding: .s)
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.l)
            }
            .foregroundColor(Color.Artemis.primaryLabel)
        }
        .tag(ExercisePath(exercise: exercise, coursePath: CoursePath(course: course)))
        .navigationLinkIndicatorVisibility(.hidden)
        .listRowBackground(Color.Artemis.exerciseCardBackgroundColor)
    }
}
