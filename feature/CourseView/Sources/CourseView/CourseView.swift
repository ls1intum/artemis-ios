import SwiftUI
import Common
import SharedModels
import Navigation

public struct CourseView: View {

    @StateObject var viewModel: CourseViewModel

    @EnvironmentObject private var navigationController: NavigationController

    public init(courseId: Int) {
        self._viewModel = StateObject(wrappedValue: CourseViewModel(courseId: courseId))
    }

    public var body: some View {
        TabView(selection: $navigationController.courseTab) {
            ExerciseListView(viewModel: viewModel)
                .tabItem {
                    Label("Exercises", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(TabIdentifier.exercise)

            Text("Lectures TODO")
                .tabItem {
                    Label("Lectures", systemImage: "character.book.closed.fill")
                }
                .tag(TabIdentifier.lecture)

            Text("Communication TODO")
                .tabItem {
                    Label("Communication", systemImage: "bubble.right.fill")
                }
                .tag(TabIdentifier.communication)
        }.navigationTitle(viewModel.course.value?.title ?? "Loading...")
    }
}
