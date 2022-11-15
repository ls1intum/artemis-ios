import SwiftUI
import Factory
import Combine

struct RootView: View {
    @StateObject private var viewController: RootViewViewController = RootViewViewController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack(path: $viewController.path) {
            EmptyView()
                    .navigationDestination(for: AccountDest.self) { _ in
                        AccountView {
                            viewController.path.removeLast()
                            viewController.path.append(CourseOverviewDest())
                        }
                    }
                    .navigationDestination(for: CourseOverviewDest.self) { _ in
                        CoursesOverviewView(
                                onClickRegisterForCourse: {
                                    viewController.path.append(CourseRegistration())
                                },
                                onNavigateToCourse: { courseId in
                                    navigateToCourseView(navigationPath: &viewController.path, courseId: courseId)
                                },
                                onLogout: {
                                    viewController.path.removeLast(viewController.path.count)
                                    viewController.path.append(AccountDest())
                                }
                        )
                    }
                    .navigationDestination(for: CourseRegistration.self) { _ in
                        CourseRegistrationView()
                    }
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
        if accountService.isLoggedIn() {
            path = NavigationPath([CourseOverviewDest()])
        } else {
            path = NavigationPath([AccountDest()])
        }
    }
}

struct AccountDest: Hashable {
}

struct CourseOverviewDest: Hashable {
}

struct CourseRegistration: Hashable {
}