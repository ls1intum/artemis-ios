//
//  CourseGridCell.swift
//
//
//  Created by Nityananda Zbil on 19.03.24.
//

import Charts
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

    struct Fraction: Identifiable {
        enum ID {
            case red
            case green
            case gray

            var color: Color {
                switch self {
                case .red:
                    return Color.Artemis.courseScoreProgressBackgroundColor
                case .green:
                    return Color.Artemis.courseScoreProgressRingColor
                case .gray:
                    return .gray
                }
            }
        }

        var id: ID
        var value: Int
    }

    var statistics: some View {
        HStack {
            Spacer()
            if let totalScore = courseForDashboard.totalScores {
                let numerator = totalScore.studentScores.absoluteScore
                let denominator = totalScore.reachablePoints
                let fraction = denominator - numerator
                let data = denominator == 0 ? [Fraction(id: .gray, value: 1)] : [.init(id: .green, value: Int(numerator)), .init(id: .red, value: Int(fraction))]
                Chart(data) { score in
                    SectorMark(
                        angle: PlottableValue.value("Score", score.value),
                        innerRadius: MarkDimension.ratio(2.0 / 3),
                        angularInset: .xxs
                    )
                    .foregroundStyle(score.id.color)
                    .cornerRadius(.l)
                }
                .chartBackground { proxy in
                    VStack {
                        Text(numerator.formatted() + " / " + denominator.formatted())
                        Text("Pts")
                    }
                }
                .frame(height: .xxxl)
                .border(Color.black)
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
