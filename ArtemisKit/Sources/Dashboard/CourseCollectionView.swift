//
//  CourseCollectionView.swift
//
//
//  Created by Nityananda Zbil on 29.11.23.
//

import CourseRegistration
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

struct CourseCollectionView: View {

    @ObservedObject var viewModel: DashboardViewModel
    @State private var isCourseRegistrationPresented = false

    var body: some View {
        DataStateView(data: $viewModel.coursesForDashboard) {
            await viewModel.loadCourses()
        } content: { coursesForDashboard in
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 400, maximum: .infinity), spacing: .l, alignment: .center)],
                    spacing: .l
                ) {
                    ForEach(coursesForDashboard) { courseForDashboard in
                        CourseCollectionContentView(courseForDashboard: courseForDashboard)
                    }
                }
                .padding(.horizontal, 20)

                HStack {
                    Spacer()
                    Button(R.string.localizable.dasboard_register_for_course()) {
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
            CourseRegistrationView(successCompletion: {
                isCourseRegistrationPresented = false
                viewModel.coursesForDashboard = .loading
                Task {
                    await viewModel.loadCourses()
                }
            })
        }
        .task {
            await viewModel.loadCourses()
        }
    }
}

private struct CourseCollectionContentView: View {

    @EnvironmentObject var navigationController: NavigationController

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

private extension CourseCollectionContentView {
    var header: some View {
        HStack(alignment: .center) {
            AsyncImage(url: courseForDashboard.course.courseIconURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .clipShape(.circle)
                case .failure:
                    Image(systemName: "questionmark.square.dashed")
                        .resizable()
                case .empty:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: .extraLargeImage, height: .extraLargeImage)
            .padding(.m)
            VStack(alignment: .leading) {
                Text(courseForDashboard.course.title ?? "")
                    .font(.custom("SF Pro", size: 21, relativeTo: .title))
                    .lineLimit(2)
                Text(R.string.localizable.dashboard_exercises_label(courseForDashboard.course.exercises?.count ?? 0))
                Text(R.string.localizable.dashboard_lectures_label(courseForDashboard.course.lectures?.count ?? 0))
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
                ProgressBar(value: Int(totalScore.studentScores.absoluteScore),
                            total: Int(totalScore.reachablePoints))
                .frame(height: 120)
                .padding(.vertical, .l)
            } else {
                Text("No statistics available")
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
                    Text(R.string.localizable.dashboard_next_exercise_label())
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
                Text(R.string.localizable.dashboard_no_exercise_planned_label())
                    .padding(.l)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.Artemis.dashboardCardBackgroundColor)
        .foregroundColor(Color.Artemis.secondaryLabel)
    }
}
