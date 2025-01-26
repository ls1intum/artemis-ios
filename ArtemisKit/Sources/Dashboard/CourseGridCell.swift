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
                content
            }
            .cardModifier(backgroundColor: .clear, hasBorder: true)
        }
        .buttonStyle(.plain)
    }
}

private extension CourseGridCell {
    var header: some View {
        HStack(alignment: .center, spacing: .m) {
            if let imageURL = courseForDashboard.course.courseIconURL {
                ArtemisAsyncImage(imageURL: imageURL) {
                    if let firstChar = courseForDashboard.course.title?.first {
                        Text(String(firstChar))
                            .font(.largeTitle)
                            .frame(width: .largeImage * 1.25, height: .largeImage * 1.25, alignment: .center)
                            .background(.regularMaterial, in: .circle)
                    }
                }
                .clipShape(.circle)
                .frame(width: .largeImage * 1.25)
            }
            Spacer()

            // If title spans multiple lines, push it to the leading edge
            // Otherwise it looks stupid
            let title = courseForDashboard.course.title ?? ""
            ViewThatFits(in: .horizontal) {
                Text(title)
                    .font(.title3)
                    .lineLimit(1)

                Text(title)
                    .font(.title3)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(.white)

            Spacer()
        }
        .frame(height: .largeImage * 1.25)
        .padding(.m)
        .frame(maxWidth: .infinity)
        .background(courseForDashboard.course.courseColor)
    }

    var content: some View {
        HStack(alignment: .center, spacing: .m) {
            information
            statisticsChart
        }
        .frame(height: .xxxl)
        .padding(.l)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    var information: some View {
        VStack(alignment: .leading) {
            Text(R.string.localizable.dashboardScoreTitle())
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
            Group {
                if let totalScore = courseForDashboard.totalScores,
                   totalScore.studentScores.absoluteScore > 0 {
                    let achieved = Int(totalScore.studentScores.absoluteScore)
                    let possible = Int(totalScore.reachablePoints)
                    Text(R.string.localizable.dashboardScoreLabel(achieved, possible))
                } else {
                    Text(R.string.localizable.dashboardNoStatisticsAvailable())
                }
            }
            .fontWeight(.semibold)

            Divider()
                .frame(height: .xxs)
                .overlay(.gray)
                .padding(.vertical, .s)

            Text(R.string.localizable.dashboardNextExerciseLabel())
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
            Group {
                if let nextExercise,
                   let nextExerciseTitle = nextExercise.baseExercise.title {
                    Text(nextExerciseTitle)
                        .lineLimit(1)
                        .onTapGesture {
                            navigationController.goToExercise(courseId: courseForDashboard.id, exerciseId: nextExercise.id)
                        }
                } else {
                    Text(R.string.localizable.dashboardNoExercisePlannedLabel())
                }
            }
            .fontWeight(.semibold)
        }
    }

    @ViewBuilder var statisticsChart: some View {
        if let totalScore = courseForDashboard.totalScores,
           totalScore.studentScores.absoluteScore > 0 {
            ProgressBar(
                value: totalScore.studentScores.absoluteScore,
                total: totalScore.reachablePoints
            )
            .foregroundStyle(Color.Artemis.secondaryLabel)
            .frame(width: .xxxl)
            .padding(.leading)
        }
    }
}

#Preview {
    CourseGridCell(courseForDashboard: CourseServiceStub.course)
}
