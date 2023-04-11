import SwiftUI
import Login
import Dashboard
import CourseRegistration
import CourseView
import Navigation
import PushNotifications
import Common

struct RootView: View {

    @StateObject private var viewModel = RootViewModel()

    @StateObject private var navigationController = NavigationController()

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if viewModel.isLoggedIn {
                if viewModel.didSetupNotifications {
                    NavigationStack(path: $navigationController.path) {
                        CoursesOverviewView()
                            .navigationDestination(for: CoursePath.self) { coursePath in
                                CourseView(courseId: coursePath.id)
                            }
                            .navigationDestination(for: ExercisePath.self) { exercisePath in
                                if let course = exercisePath.coursePath.course,
                                   let exercise = exercisePath.exercise {
                                    ExerciseDetailView(course: course, exercise: exercise)
                                } else {
                                    ExerciseDetailView(courseId: exercisePath.coursePath.id, exerciseId: exercisePath.id)
                                }
                            }
//                            .onAppear {
//                                navigationController.tryToAppendCourse()
//                                navigationController.tryToAppendExercise()
//                            }
                    }
                        .onChange(of: navigationController.path) { _ in
                            log.debug("NavigationController count: \(navigationController.path.count)")
                        }
                        .environmentObject(navigationController)
                        .onOpenURL { url in
                            DeeplinkHandler.shared.handle(url: url)
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
