import SwiftUI
import Faq
import Common
import SharedModels
import Navigation
import Messages
import Search
import DesignLibrary

public struct CourseView: View {
    @EnvironmentObject private var navigationController: NavigationController

    @StateObject private var viewModel: CourseViewModel

    private let courseId: Int

    public var body: some View {
        TabView(selection: $navigationController.courseTab) {
            Tab(R.string.localizable.exercisesTabLabel(),
                systemImage: "list.bullet.clipboard.fill",
                value: TabIdentifier.exercise) {
                TabBarIpad {
                    ExerciseListView(viewModel: viewModel)
                }
            }

            Tab(R.string.localizable.lectureTabLabel(),
                systemImage: "character.book.closed.fill",
                value: TabIdentifier.lecture) {
                TabBarIpad {
                    LectureListView(viewModel: viewModel)
                }
            }

            if viewModel.isMessagesVisible {
                Tab(R.string.localizable.messagesTabLabel(),
                    systemImage: "bubble.right.fill",
                    value: TabIdentifier.communication) {
                    TabBarIpad {
                        MessagesTabView(course: viewModel.course)
                    }
                }
            }

            if viewModel.course.faqEnabled ?? false {
                Tab(R.string.localizable.faqTabLabel(),
                    systemImage: "questionmark.circle",
                    value: TabIdentifier.faq) {
                    TabBarIpad {
                        FaqListView(course: viewModel.course)
                    }
                }
            }

            Tab(value: .search, role: .search) {
                TabBarIpad {
                    SearchTabView(courseId: viewModel.course.id)
                }
            }
        }
        .courseToolbar(title: viewModel.course.title ?? R.string.localizable.loading())
        // Add a file and image picker here, inside the navigation it doesn't work sometimes
        .supportsFilePicker()
        .supportsImagePicker()
        .autoFocusSearchOnSearchTab()
    }
}

extension CourseView {
    init(course: Course) {
        self.init(viewModel: CourseViewModel(course: course), courseId: course.id)
    }
}

private extension View {
    @ViewBuilder
    func autoFocusSearchOnSearchTab() -> some View {
        if #available(iOS 26, *) {
            tabViewSearchActivation(.searchTabSelection)
        } else {
            self
        }
    }
}
