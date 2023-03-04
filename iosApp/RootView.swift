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
