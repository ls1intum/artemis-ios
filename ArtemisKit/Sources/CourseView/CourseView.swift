import SwiftUI
import Faq
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
            TabBarIpad {
                ExerciseListView(viewModel: viewModel)
            }
            .tabItem {
                Label(R.string.localizable.exercisesTabLabel(), systemImage: "list.bullet.clipboard.fill")
            }
            .tag(TabIdentifier.exercise)

            TabBarIpad {
                LectureListView(viewModel: viewModel, searchText: $searchText)
            }
            .tabItem {
                Label(R.string.localizable.lectureTabLabel(), systemImage: "character.book.closed.fill")
            }
            .tag(TabIdentifier.lecture)

            if viewModel.isMessagesVisible {
                TabBarIpad {
                    MessagesTabView(course: viewModel.course, searchText: $searchText)
                        .environmentObject(messagesPreferences)
                }
                .tabItem {
                    Label(R.string.localizable.messagesTabLabel(), systemImage: "bubble.right.fill")
                }
                .tag(TabIdentifier.communication)
            }

            if viewModel.course.faqEnabled ?? false {
                TabBarIpad {
                    FaqListView(course: viewModel.course)
                }
                .tabItem {
                    Label(R.string.localizable.faqTabLabel(), systemImage: "questionmark.circle")
                }
                .tag(TabIdentifier.faq)
            }
        }
        .navigationTitle(viewModel.course.title ?? R.string.localizable.loading())
        .navigationBarTitleDisplayMode(.inline)
        .modifier(
            // TODO: Move search into each tab, why is this even here?
            SearchableIf(
                condition: (navigationController.courseTab != .communication || messagesPreferences.isSearchable) && navigationController.courseTab != .faq,
                text: $searchText)
        )
        .onChange(of: navigationController.courseTab) {
            searchText = ""
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
