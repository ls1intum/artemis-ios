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

    @StateObject private var viewModel = CoursesOverviewViewModel()

    @State private var showCourseRegistrationSheet = false
    @State private var showNotificationSheet = false

    public init() { }

    public var body: some View {
        VStack(alignment: .center) {
            DataStateView(data: $viewModel.courses,
                          retryHandler: { await viewModel.loadCourses() }) { courses in
                List {
                    Group {
                        ForEach(courses) { course in
                            CourseListCell(course: course)
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
        .navigationDestination(for: CoursePath.self) { coursePath in
            CourseView(courseId: coursePath.id)
        }
        .navigationTitle(Text(R.string.localizable.dashboard_title()))
        .accountMenu(error: $viewModel.error)
        .notificationToolBar()
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
            }
        }
        .sheet(isPresented: $showCourseRegistrationSheet) {
            CourseRegistrationView(successCompletion: {
                showCourseRegistrationSheet = false
                viewModel.courses = .loading
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

    let course: Course

    var nextExercise: Exercise? {
        // filters out every already successful (100%) exercise, only exercises left that still need work
        let exercisesWithOpenTasks = course.upcomingExercises.filter { exercise in
            return !(exercise.baseExercise.studentParticipations?.first?.baseParticipation.submissions?.first?.baseSubmission.results?.first?.successful ?? false)
        }
        return exercisesWithOpenTasks.first
    }

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    AsyncImage(url: course.courseIconURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            Image("questionmark.square.dashed")
                        @unknown default:
                            EmptyView()
                        }
                    }
                        .frame(width: .extraLargeImage, height: .extraLargeImage)
                        .clipShape(Circle())
                        .padding(.m)
                    VStack(alignment: .leading) {
                        Text(course.title ?? R.string.localizable.unknown())
                            .font(.custom("SF Pro", size: 21, relativeTo: .title))
                            .lineLimit(2)
                        Text(R.string.localizable.dashboard_exercises_label(course.exercises?.count ?? 0))
                        Text(R.string.localizable.dashboard_lectures_label(course.lectures?.count ?? 0))
                    }
                        .foregroundColor(.white)
                        .padding(.m)
                    Spacer()
                }
                    .frame(maxWidth: .infinity)
                    .background(course.courseColor)
                HStack {
                    Spacer()
                    ProgressBar(value: 40,
                                total: 100,
                                color: course.courseColor)
                        .frame(height: 120)
                        .padding(.vertical, .l)
                    Spacer()
                }.padding(.vertical, .m)
                HStack {
                    if let nextExercise {
                        HStack {
                            Text(R.string.localizable.dashboard_next_exercise_label())
                                .padding(.trailing, .m)
                            nextExercise.image
                                .resizable()
                                .scaledToFit()
                                .frame(width: .extraSmallImage)
                            Text(nextExercise.baseExercise.title ?? R.string.localizable.unknown())
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
                    navigationController.path.append(CoursePath(course: course))
                }
                .frame(maxWidth: 720)
            Spacer()
        }
    }
}
