import SwiftUI
import Login
import Dashboard
import CourseRegistration
import CourseView
import Navigation
import PushNotifications

struct RootView: View {

    @StateObject private var viewModel = RootViewModel()

    @EnvironmentObject var navigationController: NavigationController

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if viewModel.isLoggedIn {
                if viewModel.didSetupNotifications {
                    NavigationStack(path: $navigationController.path) {
                        CoursesOverviewView()
                    }
                } else {
                    PushNotificationSetupView()
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
