import SwiftUI
import Login
import Dashboard
import CourseRegistration
import CourseView
import Navigation
import PushNotifications
import Common
import Messages

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
                                    .id(coursePath.id)
                            }
                            // Sadly the following navigationDestination have to be here since SwiftUI is ...
                            .navigationDestination(for: ExercisePath.self) { exercisePath in
                                if let course = exercisePath.coursePath.course,
                                   let exercise = exercisePath.exercise {
                                    ExerciseDetailView(course: course, exercise: exercise)
                                } else {
                                    ExerciseDetailView(courseId: exercisePath.coursePath.id, exerciseId: exercisePath.id)
                                }
                            }
                            .navigationDestination(for: MessagePath.self) { messagePath in
                                if let message = messagePath.message,
                                   let conversation = messagePath.conversationPath.conversation {
                                    MessageDetailView(viewModel: ConversationViewModel(courseId: messagePath.coursePath.id,
                                                                                       conversation: conversation),
                                                      message: message)
                                } else {
                                    MessageDetailView(viewModel: ConversationViewModel(courseId: messagePath.coursePath.id,
                                                                                       conversationId: messagePath.conversationPath.id),
                                                      messageId: messagePath.id)
                                }
                            }
                            .navigationDestination(for: ConversationPath.self) { conversationPath in
                                if let conversation = conversationPath.conversation {
                                    ConversationView(courseId: conversationPath.coursePath.id,
                                                     conversation: conversation)
                                } else {
                                    ConversationView(courseId: conversationPath.coursePath.id,
                                                     conversationId: conversationPath.id)
                                }
                            }
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
