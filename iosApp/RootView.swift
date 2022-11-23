import SwiftUI
import Factory
import Combine
import Datastore
import Login
import Dashboard
import CourseRegistration
import CourseView

struct RootView: View {
    @StateObject private var viewController: RootViewViewController = RootViewViewController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack(path: $viewController.path) {
            EmptyView()
                    .accountDestination(
                            onLoggedIn: {
                                viewController.path.removeLast()
                                viewController.path.appendDashboard()
                            }
                    )
                    .dashboardDestination(
                            onLogout: {
                                viewController.path.removeLast(viewController.path.count)
                                viewController.path.appendAccountView()
                            },
                            onClickRegisterForCourse: {
                                viewController.path.appendCourseRegistration()
                            },
                            onViewCourse: { courseId in
                                viewController.path.appendCourseView(courseId: courseId)
                            }
                    )
                    .courseRegistrationDestination(
                            onNavigateUp: {
                                viewController.path.removeLast()
                            },
                            onRegisteredInCourse: { courseId in
                                viewController.path.removeLast()
                                viewController.path.appendCourseView(courseId: courseId)
                            }
                    )
                    .courseViewDestination()
        }
                .onChange(of: scenePhase) { phase in
                    if phase == .background {
                        //viewController.save()
                    }
                }
    }
}

class RootViewViewController: ObservableObject {
    private let accountService: AccountService = Container.accountService()

    @Published var path: NavigationPath

    init() {
        path = NavigationPath()
        if accountService.isLoggedIn() {
            path.appendDashboard()
        } else {
            path.appendAccountView()
        }
    }
}
