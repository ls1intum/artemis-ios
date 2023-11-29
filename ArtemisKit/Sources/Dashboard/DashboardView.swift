import Account
import Common
import CourseRegistration
import CourseView
import DesignLibrary
import Navigation
import Notifications
import SharedModels
import SwiftUI

/**
 * Display the course overview with the course list.
 */
public struct DashboardView: View {

    @StateObject private var viewModel = DashboardViewModel()

    @State private var isCourseRegistrationPresented = false

    public init() { }

    public var body: some View {
        DataStateView(data: $viewModel.coursesForDashboard, retryHandler: {
            await viewModel.loadCourses()
        }, content: { coursesForDashboard in
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 400, maximum: .infinity), spacing: .l, alignment: .center)
                ], spacing: .l, content: {
                    ForEach(coursesForDashboard[..<10]) { courseForDashboard in
                        CourseListCell(courseForDashboard: courseForDashboard)
                    }
                })
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
        })
        .navigationTitle(Text(R.string.localizable.dashboard_title()))
        .accountMenu(error: $viewModel.error)
        .notificationToolBar()
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
        .sheet(isPresented: $isCourseRegistrationPresented) {
            CourseRegistrationView(successCompletion: {
                isCourseRegistrationPresented = false
                viewModel.coursesForDashboard = .loading
                Task {
                    await viewModel.loadCourses()
                }
            })
        }
        .navigationBarBackButtonHidden()
        .task {
            await viewModel.loadCourses()
        }
    }
}

private struct CourseListCell: View {

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
        if let title = courseForDashboard.course.title {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    if let url = courseForDashboard.course.courseIconURL {
                        ArtemisAsyncImage(imageURL: url) {
                            Image("questionmark.square.dashed")
                        }
                        .frame(width: .extraLargeImage, height: .extraLargeImage)
                        .clipShape(Circle())
                        .padding(.m)
                    }
                    VStack(alignment: .leading) {
                        Text(title)
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
                HStack {
                    Spacer()
                    Group {
                        if let totalScore = courseForDashboard.totalScores {
                            ProgressBar(value: Int(totalScore.studentScores.absoluteScore),
                                        total: Int(totalScore.reachablePoints))
                            .frame(height: 120)
                            .padding(.vertical, .l)
                        } else {
                            Text("No statistics available")
                        }
                    }
                    Spacer()
                }.padding(.vertical, .m)
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
                        }.padding(.l)
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
            .cardModifier(backgroundColor: .clear, hasBorder: true)
            .onTapGesture {
                navigationController.path.append(CoursePath(course: courseForDashboard.course))
            }
            .frame(maxWidth: 720)
        } else {
            EmptyView()
        }
    }
}
