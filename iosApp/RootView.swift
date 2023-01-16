import SwiftUI
import Login
import Dashboard
import CourseRegistration
import CourseView

struct RootView: View {
    
    @StateObject private var viewModel = RootViewModel()
    
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if viewModel.isLoggedIn {
                NavigationStack(path: $viewModel.path) {
                    EmptyView()
                        .dashboardDestination(
                            onLogout: {
                                viewModel.path.removeLast(viewModel.path.count)
                                viewModel.path.appendAccountView()
                            },
                            onClickRegisterForCourse: {
                                viewModel.path.appendCourseRegistration()
                            },
                            onViewCourse: { courseId in
                                viewModel.path.appendCourseView(courseId: courseId)
                            }
                        )
                        .courseRegistrationDestination(
                            onNavigateUp: {
                                viewModel.path.removeLast()
                            },
                            onRegisteredInCourse: { courseId in
                                viewModel.path.removeLast()
                                viewModel.path.appendCourseView(courseId: courseId)
                            }
                        )
                        .courseViewDestination()
                }
            } else {
                LoginView()
            }
        }
            .onChange(of: scenePhase) { phase in
                if phase == .background {
                    //viewModel.save()
                }
            }
    }
}
