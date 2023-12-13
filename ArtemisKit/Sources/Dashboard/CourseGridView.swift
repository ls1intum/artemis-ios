//
//  CourseGridView.swift
//
//
//  Created by Nityananda Zbil on 29.11.23.
//

import CourseRegistration
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

struct CourseGridView: View {

    private static let layout = [GridItem(.adaptive(minimum: 400, maximum: .infinity), spacing: .l, alignment: .center)]

    @ObservedObject var viewModel: DashboardViewModel
    @State private var isCourseRegistrationPresented = false

    var body: some View {
        DataStateView(data: $viewModel.coursesForDashboard) {
            await viewModel.loadCourses()
        } content: { coursesForDashboard in
            ScrollView {
                LazyVGrid(columns: Self.layout, spacing: .l) {
                    ForEach(coursesForDashboard) { courseForDashboard in
                        CourseGridContentView(courseForDashboard: courseForDashboard)
                    }
                }
                .padding(.horizontal, 20)

                HStack {
                    Spacer()
                    Button(R.string.localizable.dashboardRegisterForCourseButton()) {
                        isCourseRegistrationPresented = true
                    }
                    .buttonStyle(ArtemisButton())
                    Spacer()
                }
            }
            .refreshable {
                await viewModel.loadCourses()
            }
        }
        .sheet(isPresented: $isCourseRegistrationPresented) {
            CourseRegistrationView {
                isCourseRegistrationPresented = false
                viewModel.coursesForDashboard = .loading
                Task {
                    await viewModel.loadCourses()
                }
            }
        }
        .task {
            await viewModel.loadCourses()
        }
    }
}

private struct CourseGridContentView: View {

    @EnvironmentObject private var navigationController: NavigationController

    let courseForDashboard: CourseForDashboard

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
        VStack(alignment: .leading, spacing: 0) {
            header
            statistics
            footer
        }
        .cardModifier(backgroundColor: .clear, hasBorder: true)
        .onTapGesture {
            navigationController.path.append(CoursePath(course: courseForDashboard.course))
        }
    }
}

private extension CourseGridContentView {
    var header: some View {
        HStack(alignment: .center) {
            AsyncImage(url: courseForDashboard.course.courseIconURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .clipShape(.circle)
                        .frame(width: .extraLargeImage)
                        .padding(.m)
                case .failure:
                    Image(systemName: "questionmark.square.dashed")
                        .resizable()
                        .frame(width: .extraLargeImage)
                        .padding(.m)
                case .empty:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: .extraLargeImage)
            VStack(alignment: .leading) {
                Text(courseForDashboard.course.title ?? "")
                    .font(.custom("SF Pro", size: 21, relativeTo: .title))
                    .lineLimit(2)
                Text(R.string.localizable.dashboardExercisesLabel(courseForDashboard.course.exercises?.count ?? 0))
                Text(R.string.localizable.dashboardLecturesLabel(courseForDashboard.course.lectures?.count ?? 0))
            }
            .foregroundColor(.white)
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
                    total: Int(totalScore.reachablePoints))
                .frame(height: 120)
                .padding(.vertical, .l)
            } else {
                Text(R.string.localizable.dashboardNoStatisticsAvailable())
            }
            Spacer()
        }
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
        .foregroundColor(Color.Artemis.secondaryLabel)
    }
}
