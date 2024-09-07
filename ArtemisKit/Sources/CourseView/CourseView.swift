import SwiftUI
import Common
import SharedModels
import Navigation
import Messages
import DesignLibrary

public struct CourseView: View {
    @EnvironmentObject private var navigationController: NavigationController

    @StateObject private var viewModel: CourseViewModel
    @StateObject private var messagesPreferences = MessagesPreferences()

    @State private var showNewMessageDialog = false
    @State private var searchText = ""

    private let courseId: Int

    public var body: some View {
        TabView(selection: $navigationController.courseTab) {
            ExerciseListView(viewModel: viewModel, searchText: $searchText)
                .tabItem {
                    Label(R.string.localizable.exercisesTabLabel(), systemImage: "list.bullet.clipboard.fill")
                }
                .tag(TabIdentifier.exercise)

            LectureListView(viewModel: viewModel, searchText: $searchText)
                .tabItem {
                    Label(R.string.localizable.lectureTabLabel(), systemImage: "character.book.closed.fill")
                }
                .tag(TabIdentifier.lecture)

            if viewModel.isMessagesVisible {
                MessagesTabView(course: viewModel.course, searchText: $searchText)
                    .environmentObject(messagesPreferences)
                    .tabItem {
                        Label(R.string.localizable.messagesTabLabel(), systemImage: "bubble.right.fill")
                    }
                    .tag(TabIdentifier.communication)
            }
        }
        .navigationTitle(viewModel.course.title ?? R.string.localizable.loading())
        .navigationBarTitleDisplayMode(.inline)
        .modifier(
            SearchableIf(
                condition: navigationController.courseTab != .communication || messagesPreferences.isSearchable,
                text: $searchText)
        )
        .onChange(of: navigationController.courseTab) {
            searchText = ""
        }
        .onDisappear {
            if navigationController.outerPath.count < 2 {
                // Reset selection if navigating back
                navigationController.selectedPath = nil
            }
        }
        .onAppear {
            // On iPad, always make Tab Bar opaque
            // This prevents an issue where the tab bar has content behind it but is transparent
            if UIDevice.current.userInterfaceIdiom == .pad {
                let appearance = UITabBarAppearance()
                appearance.configureWithDefaultBackground()
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

extension CourseView {
    init(course: Course) {
        self.init(viewModel: CourseViewModel(course: course), courseId: course.id)
    }
}

/// `SearchableIf` modifies a view to be searchable if the condition is true.
///
/// It appears, the `.searchable` modifier cannot be deeper in the hierarchy, i.e., further from the enclosing `NavigationStack`.
private struct SearchableIf: ViewModifier {
    let condition: Bool
    let text: Binding<String>

    func body(content: Content) -> some View {
        if condition {
            content
                .searchable(text: text)
        } else {
            content
        }
    }
}
