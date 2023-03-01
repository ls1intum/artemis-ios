import SwiftUI
import Common
import SharedModels

public struct CourseView: View {

    @StateObject var viewModel: CourseViewModel

    @State private var tabSelection: TabIdentifier = .exercise

    public init(course: Course) {
        self._viewModel = StateObject(wrappedValue: CourseViewModel(course: course))
    }

    public var body: some View {
        TabView(selection: $tabSelection) {
            Text("Exercises TODO")
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

private enum TabIdentifier {
    case exercise, lecture, communication
}
