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

    @ObservedObject private var navigationController: NavigationController

    public init(navigationController: NavigationController) {
        self.navigationController = navigationController
    }

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
                        contentView
                            .onChange(of: navigationController.outerPath) {
                                log.debug("NavigationController count: \(navigationController.outerPath.count)")
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

extension RootView {
    @ViewBuilder var contentView: some View {
        ZStack {
            NavigationStack {
                DashboardView()
            }
            .zIndex(0)

            if let selectedCourse = navigationController.selectedCourse {
                CoursePathView(path: selectedCourse)
                    .transition(.move(edge: .trailing))
                    .id(selectedCourse.id)
                    .zIndex(1)
            }

            NavigationStack(path: $navigationController.outerPath) {
                Color.clear
                    .modifier(NavigationDestinationRootViewModifier())
            }
            .toolbarBackground(.hidden)
            .opacity(navigationController.outerPath.isEmpty ? 0 : 1)
            .zIndex(2)
        }
        .animation(.easeOut(duration: 0.3), value: navigationController.selectedCourse)
    }
}

public struct NavigationDestinationRootViewModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .navigationDestination(for: CoursePath.self, destination: CoursePathView.init)
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
            .modifier(NavigationDestinationMessagesModifier())
    }
}
