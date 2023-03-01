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
                    Label("Exercises", image: "list.dash")
                }
                .tag(TabIdentifier.exercise)

            Text("Lectures TODO")
                .tabItem {
                    Label("Lectures", image: "list.dash")
                }
                .tag(TabIdentifier.lecture)

            Text("Communication TODO")
                .tabItem {
                    Label("Communication", image: "list.dash")
                }
                .tag(TabIdentifier.communication)
        }.navigationTitle(viewModel.course.value?.title ?? "Loading...")
    }
}

private enum TabIdentifier {
    case exercise, lecture, communication
}
