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

            Text("Lectures TODO")
                .tabItem {
                    Label(R.string.localizable.lectureTabLabel(), systemImage: "character.book.closed.fill")
                }
                .tag(TabIdentifier.lecture)

            if viewModel.course.value == nil ||
                viewModel.course.value?.courseInformationSharingConfiguration == .communicationAndMessaging ||
                viewModel.course.value?.courseInformationSharingConfiguration == .messagingOnly {
                Group {
                    if let course = viewModel.course.value {
                        MessagesTabView(searchText: $searchText, course: course)
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
            .searchable(text: $searchText)
            .onChange(of: navigationController.courseTab) { _ in
                searchText = ""
            }
    }
}
