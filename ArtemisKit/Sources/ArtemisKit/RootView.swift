import Common
import CourseRegistration
import CourseView
import Dashboard
import Login
import Messages
import Navigation
import PushNotifications
import SwiftUI

public struct RootView: View {

    @StateObject private var viewModel = RootViewModel()

    @StateObject private var navigationController = NavigationController()

    public init() {}

    public var body: some View {
        Group {
            if viewModel.isLoading {
                Image("Artemis-Logo", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: .extraLargeImage)
            } else {
                if viewModel.isLoggedIn {
                    if viewModel.didSetupNotifications {
                        NavigationStack(path: $navigationController.path) {
                            DashboardView()
                                .modifier(NavigationDestinationRootViewModifier())
                        }
                        .onChange(of: navigationController.path) {
                            log.debug("NavigationController count: \(navigationController.path.count)")
                        }
                        .environmentObject(navigationController)
                        .onOpenURL { url in
                            DeeplinkHandler.shared.handle(url: url)
                        }
                        .environment(\.openURL, OpenURLAction { url in
                            if DeeplinkHandler.shared.handle(url: url) {
                                return .handled
                            } else {
                                return .systemAction
                            }
                        })
                    } else {
                        PushNotificationSetupView()
                    }
                } else {
                    LoginView()
                }
            }
        }
        .alert("Link not supported by App", isPresented: $navigationController.showDeeplinkNotSupported, actions: {
            Button("OK", role: .cancel) {
                navigationController.showDeeplinkNotSupported = false
            }
            if let url = navigationController.notSupportedUrl {
                Button("Open in Browser") {
                    UIApplication.shared.open(url)
                }
            }
        })
    }
}

private struct NavigationDestinationRootViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: CoursePath.self) { coursePath in
                CourseView(courseId: coursePath.id)
                    .id(coursePath.id)
            }
            .navigationDestination(for: ExercisePath.self) { exercisePath in
                if let course = exercisePath.coursePath.course,
                   let exercise = exercisePath.exercise {
                    ExerciseDetailView(course: course, exercise: exercise)
                } else {
                    ExerciseDetailView(courseId: exercisePath.coursePath.id, exerciseId: exercisePath.id)
                }
            }
            .navigationDestination(for: LecturePath.self) { lecturePath in
                if let course = lecturePath.coursePath.course {
                    LectureDetailView(course: course, lectureId: lecturePath.id)
                } else {
                    LectureDetailView(courseId: lecturePath.coursePath.id, lectureId: lecturePath.id)
                }
            }
            .navigationDestination(for: ConversationPath.self) { conversationPath in
                if let conversation = conversationPath.conversation,
                   let course = conversationPath.coursePath.course {
                    ConversationView(course: course,
                                     conversation: conversation)
                } else {
                    ConversationView(courseId: conversationPath.coursePath.id,
                                     conversationId: conversationPath.id)
                }
            }
            .modifier(NavigationDestinationThreadViewModifier())
    }
}
