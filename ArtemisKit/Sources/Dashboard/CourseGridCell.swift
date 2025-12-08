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
    @Environment(\.dismissSearch) private var dismissSearch

    let courseForDashboard: CourseForDashboardDTO
    let viewModel: DashboardViewModel

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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Update recents with a delay to not update grid during navigation transition
                viewModel.addToRecents(courseId: courseForDashboard.id)
            }
            dismissSearch()
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
            ArtemisAsyncImage(imageURL: courseForDashboard.course.courseIconURL) {
                if let firstChar = courseForDashboard.course.title?.first {
                    Text(String(firstChar))
                        .font(.largeTitle)
                        .frame(width: .largeImage * 1.25, height: .largeImage * 1.25, alignment: .center)
                        .background(.regularMaterial, in: .circle)
                }
            }
            .clipShape(.circle)
            .frame(width: .largeImage * 1.25)

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
            .foregroundStyle(headerTextColor)

            Spacer()
        }
        .frame(height: .largeImage * 1.25)
        .padding(.m)
        .frame(maxWidth: .infinity)
        .background(courseForDashboard.course.courseColor)
    }

    // Ensure contrast between background and title color is big enough
    var headerTextColor: Color {
        guard let color = courseForDashboard.course.color,
              let colorComponents = UIColor(hexString: color).cgColor.components,
              colorComponents.count >= 3 else {
            return .white
        }
        let r = colorComponents[0]
        let g = colorComponents[1]
        let b = colorComponents[2]
        let brightness = (r * 299 + g * 587 + b * 114) / 3.9
        if brightness >= 128 {
            return .black
        } else {
            return .white
        }
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
                    let achieved = round(totalScore.studentScores.absoluteScore * 10) / 10
                    let possible = round(totalScore.reachablePoints * 10) / 10
                    Text(R.string.localizable.dashboardScoreLabel(achieved.clean, possible.clean))
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
                            dismissSearch()
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
           totalScore.studentScores.absoluteScore > 0 && totalScore.reachablePoints > 0 {
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

private extension Double {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

#Preview {
    CourseGridCell(courseForDashboard: CourseServiceStub.course, viewModel: .init())
}
