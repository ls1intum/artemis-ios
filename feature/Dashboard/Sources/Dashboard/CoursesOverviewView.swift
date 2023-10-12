import SwiftUI
import Common
import SharedModels
import CourseRegistration
import DesignLibrary
import Navigation
import CourseView
import Account
import Notifications

/**
 * Display the course overview with the course list.
 */
public struct CoursesOverviewView: View {

    @StateObject private var viewModel: CoursesOverviewViewModel

    @State private var showCourseRegistrationSheet = false
    @State private var showNotificationSheet = false

    public init() { 
        _viewModel = .init(wrappedValue: CoursesOverviewViewModel())
    }

    init(viewModel: CoursesOverviewViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(alignment: .center) {
            DataStateView(data: $viewModel.coursesForDashboard,
                          retryHandler: { await viewModel.loadCourses() }) { coursesForDashboard in
                List {
                    Group {
                        ForEach(coursesForDashboard) { courseForDashboard in
                            CourseListCell(courseForDashboard: courseForDashboard,
                                           courseIconURLForCourse: viewModel.courseIconURL(for:))
                        }
                        Button(R.string.localizable.dasboard_register_for_course()) {
                            showCourseRegistrationSheet = true
                        }
                            .buttonStyle(ArtemisButton())
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.loadCourses()
                }
            }
        }
        .navigationTitle(Text(R.string.localizable.dashboard_title()))
        .accountMenu(error: $viewModel.error)
        .notificationToolBar()
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
        .sheet(isPresented: $showCourseRegistrationSheet) {
            CourseRegistrationView(successCompletion: {
                showCourseRegistrationSheet = false
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

    let courseIconURLForCourse: (Course) -> URL?

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
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        if let url = courseIconURLForCourse(courseForDashboard.course) {
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
                Spacer()
            }
        } else {
            EmptyView()
        }
    }
}
