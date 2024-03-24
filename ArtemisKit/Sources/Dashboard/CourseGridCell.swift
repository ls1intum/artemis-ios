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
            guard let participation = exercise.baseExercise.studentParticipations?.first,
                  let submission = participation.baseParticipation.submissions?.first,
                  let result = submission.baseSubmission.results?.first else {
                return false
            }
            return !(result?.successful ?? false)
        }
        return exercisesWithOpenTasks.first
    }

    var body: some View {
        Button {
            navigationController.path.append(CoursePath(course: courseForDashboard.course))
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
        HStack(alignment: .center) {
            AsyncImage(url: courseForDashboard.course.courseIconURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .clipShape(.circle)
                        .frame(width: .extraLargeImage)
                case .failure, .empty:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: .extraLargeImage)
            .padding([.leading, .vertical], .m)
            VStack(alignment: .leading, spacing: 0) {
                Text(courseForDashboard.course.title ?? "")
                    .font(.custom("SF Pro", size: 21, relativeTo: .title))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(R.string.localizable.dashboardExercisesLabel(courseForDashboard.course.exercises?.count ?? 0))
                Text(R.string.localizable.dashboardLecturesLabel(courseForDashboard.course.lectures?.count ?? 0))
            }
            .foregroundStyle(.white)
            .padding(.m)
            Spacer()
        }
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
