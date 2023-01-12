import SwiftUI
import Combine
import SDWebImageSwiftUI
import SDWebImage
import Model
import UI

public extension View {
    func dashboardDestination(onLogout: @escaping () -> Void, onClickRegisterForCourse: @escaping () -> Void, onViewCourse: @escaping (_ courseId: Int) -> Void) -> some View {
        navigationDestination(for: CourseOverviewDest.self) { _ in
            CoursesOverviewView(onClickRegisterForCourse: onClickRegisterForCourse, onNavigateToCourse: onViewCourse, onLogout: onLogout)
        }
    }
}

public extension NavigationPath {
    mutating func appendDashboard() {
        append(CourseOverviewDest())
    }
}

struct CourseOverviewDest: Hashable {
}

/**
 * Display the course overview with the course list.
 */
struct CoursesOverviewView: View {

    @StateObject var viewModel: CoursesOverviewViewModel = CoursesOverviewViewModel()
    let onClickRegisterForCourse: () -> Void
    let onNavigateToCourse: (_ courseId: Int) -> Void
    let onLogout: () -> Void

    var body: some View {
        VStack(alignment: .center) {
            BasicDataStateView(
                    data: viewModel.dashboard,
                    loadingText: "course_overview_loading_courses_loading",
                    failureText: "course_overview_loading_courses_failed",
                    suspendedText: "course_overview_loading_courses_suspended",
                    retryButtonText: "course_overview_loading_courses_button_try_again",
                    clickRetryButtonAction: {
                        Task {
                            await viewModel.reloadDashboard()
                        }
                    }
            ) { data in
                ZStack {
                    CourseListView(
                            courses: data.courses,
                            serverUrl: viewModel.serverUrl,
                            bearer: viewModel.bearer,
                            onClickCourse: { course in onNavigateToCourse(course.id ?? 0) }
                    )
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
                .navigationTitle(Text("course_overview_title"))
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: onClickRegisterForCourse, label: {
                            Label("course_overview_register_button_text", systemImage: "pencil")
                        })

                        Button("Logout") {
                            viewModel.logout()
                            onLogout()
                        }
                    }
                }
                .navigationBarBackButtonHidden()
                .task {
                    await viewModel.reloadDashboard()
                }
    }
}

/**
 * Displays a lazy list of all the courses supplied.
 */
private struct CourseListView: View {

    let courses: [Course]
    let serverUrl: String
    let bearer: String
    let onClickCourse: (Course) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(courses, id: \.self.id) { course in
                    CourseItemView(course: course, serverUrl: serverUrl, bearer: bearer, onClick: { onClickCourse(course) })
                            .padding(.horizontal, 8)
                }
            }
        }
    }
}

private struct CourseItemView: View {
    let course: Course
    let serverUrl: String
    let bearer: String
    let onClick: () -> Void

    var body: some View {
        CoursesHeaderView(
                course: course
        ) {
            VStack(spacing: 0) {
                Divider()

                HStack(spacing: 8) {
                    ProgressView(value: 0.4)
                            .frame(maxWidth: .infinity)

                    Text("30P/40P (12%)")
                }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
            }
        }
                .onTapGesture {
                    onClick()
                }
    }
}


class CoursesOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let serverUrl = "https://via.placeholder.com"

            let sampleCourse = Course(id: 12, title: "Sample Course", description: "Sample Course Description", courseIcon: "/150/0000FF")
//
//            let courses = [sampleCourse,
//                           Course(id: 13,
//                                   title: "Other Course", description: "Playing with penguins", courseIconPath: "/150/0000FF"),
//                           Course(id: 14,
//                                   title: "Another Course", description: "Description 123", courseIconPath: "/150/0000FF"),
//            ]
//
//            CoursesList(courses: courses, serverUrl: "", bearer: "")
//
            CourseItemView(course: sampleCourse, serverUrl: serverUrl, bearer: "", onClick: {})
        }
    }
}
