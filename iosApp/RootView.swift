import SwiftUI
import Login
import Dashboard
import CourseRegistration
import CourseView
import Navigation

struct RootView: View {

    @StateObject private var viewModel = RootViewModel()

    @EnvironmentObject var navigationController: NavigationController

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if viewModel.isLoggedIn {
                NavigationStack(path: $navigationController.path) {
                    CoursesOverviewView()

//                    EmptyView()
//                        .dashboardDestination(
//                            onLogout: {
//                                viewModel.path.removeLast(viewModel.path.count)
//                            },
//                            onClickRegisterForCourse: {
//                                viewModel.path.appendCourseRegistration()
//                            },
//                            onViewCourse: { courseId in
//                                viewModel.path.appendCourseView(courseId: courseId)
//                            }
//                        )
//                        .courseRegistrationDestination(
//                            onNavigateUp: {
//                                viewModel.path.removeLast()
//                            },
//                            onRegisteredInCourse: { courseId in
//                                viewModel.path.removeLast()
//                                viewModel.path.appendCourseView(courseId: courseId)
//                            }
//                        )
//                        .courseViewDestination()
                }
            } else {
                LoginView()
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                // viewModel.save()
            }
        }
    }
}
