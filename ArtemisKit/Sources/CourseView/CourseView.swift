import SwiftUI
import Faq
import Common
import SharedModels
import Navigation
import Messages
import DesignLibrary

public struct CourseView: View {
    @EnvironmentObject private var navigationController: NavigationController
    @Environment(\.horizontalSizeClass) private var sizeClass

    @StateObject private var viewModel: CourseViewModel

    @State private var showNewMessageDialog = false

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
                LectureListView(viewModel: viewModel)
            }
            .tabItem {
                Label(R.string.localizable.lectureTabLabel(), systemImage: "character.book.closed.fill")
            }
            .tag(TabIdentifier.lecture)

            if viewModel.isMessagesVisible {
                TabBarIpad {
                    MessagesTabView(course: viewModel.course)
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
        .courseToolbar(title: viewModel.course.title  ?? R.string.localizable.loading())
        // Add a file and image picker here, inside the navigation it doesn't work sometimes
        .supportsFilePicker()
        .supportsImagePicker()
    }
}

extension CourseView {
    init(course: Course) {
        self.init(viewModel: CourseViewModel(course: course), courseId: course.id)
    }
}
