//
//  CourseGridCell.swift
//
//
//  Created by Nityananda Zbil on 19.03.24.
//

import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

struct CourseGridCell: View {
    @EnvironmentObject private var navigationController: NavigationController

    let courseForDashboard: CourseForDashboardDTO

    var nextExercise: Exercise? {
        // filters out every already successful (100%) exercise, only exercises left that still need work
        let exercisesWithOpenTasks = courseForDashboard.course.upcomingExercises.filter { exercise in
            if let participation = exercise.baseExercise.studentParticipations?.first,
               let submission = participation.baseParticipation.submissions?.first,
               let result = submission.baseSubmission.results?.first,
               let success = result?.successful {
                return !success
            }
            return true
        }
        return exercisesWithOpenTasks.first
    }

    var body: some View {
        Button {
            navigationController.selectedCourse = CoursePath(id: courseForDashboard.id)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                header
                statistics
                footer
            }
            .cardModifier(backgroundColor: .clear, hasBorder: true)
        }
    }
}

private extension CourseGridCell {
    var header: some View {
        HStack(alignment: .center, spacing: .m) {
            if let imageURL = courseForDashboard.course.courseIconURL {
                ArtemisAsyncImage(imageURL: imageURL) {
                    EmptyView()
                }
                .clipShape(.circle)
                .frame(width: .largeImage * 1.25)
            }
            Spacer()
            Text(courseForDashboard.course.title ?? "")
                .font(.title3)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .foregroundStyle(.white)
            Spacer()
        }
        .frame(height: .largeImage * 1.25)
        .padding(.m)
        .frame(maxWidth: .infinity)
        .background(courseForDashboard.course.courseColor)
    }

    var statistics: some View {
        HStack {
            Spacer()
            if let totalScore = courseForDashboard.totalScores {
                ProgressBar(
                    value: Int(totalScore.studentScores.absoluteScore),
                    total: Int(totalScore.reachablePoints)
                )
                .frame(height: .xxxl)
            } else {
                Text(R.string.localizable.dashboardNoStatisticsAvailable())
            }
            Spacer()
        }
        .foregroundStyle(Color.Artemis.secondaryLabel)
        .padding(.vertical, .m)
    }

    var footer: some View {
        HStack {
            if let nextExercise,
               let nextExerciseTitle = nextExercise.baseExercise.title {
                HStack {
                    Text(R.string.localizable.dashboardNextExerciseLabel())
                        .padding(.trailing, .m)
                    nextExercise.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: .extraSmallImage)
                    Text(nextExerciseTitle)
                        .bold()
                        .lineLimit(1)
                }
                .padding(.l)
            } else {
                Text(R.string.localizable.dashboardNoExercisePlannedLabel())
                    .padding(.l)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.Artemis.dashboardCardBackgroundColor)
        .foregroundStyle(Color.Artemis.secondaryLabel)
    }
}

#Preview {
    CourseGridCell(courseForDashboard: CourseServiceStub.course)
}
