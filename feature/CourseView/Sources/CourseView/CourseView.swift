import SwiftUI
import Common
import SharedModels
import Navigation
import Messages
import DesignLibrary

public struct CourseView: View {

    @StateObject var viewModel: CourseViewModel

    @EnvironmentObject private var navigationController: NavigationController

    @State private var showNewMessageDialog = false
    @State private var searchText = ""
    @State private var isMessagesSearchable = true

    private let courseId: Int

    public init(courseId: Int) {
        self.courseId = courseId
        self._viewModel = StateObject(wrappedValue: CourseViewModel(courseId: courseId))
    }

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
                Group {
                    if let course = viewModel.course.value {
                        MessagesTabView(course: course, searchText: $searchText, isSearchable: $isMessagesSearchable)
                    } else {
                        Text("Loading...")
                    }
                }
                .tabItem {
                    Label(R.string.localizable.messagesTabLabel(), systemImage: "bubble.right.fill")
                }
                .tag(TabIdentifier.communication)
            }
        }
        .navigationTitle(viewModel.course.value?.title ?? R.string.localizable.loading())
        .navigationBarTitleDisplayMode(.inline)
        .modifier(SearchableIf(condition: navigationController.courseTab != .communication || isMessagesSearchable, text: $searchText))
        .onChange(of: navigationController.courseTab) {
            searchText = ""
        }
    }
}

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
