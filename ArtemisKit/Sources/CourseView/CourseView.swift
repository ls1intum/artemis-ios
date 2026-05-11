import SwiftUI
import Faq
import Common
import SharedModels
import Navigation
import Messages
import ProfileInfo
import Search
import DesignLibrary

public struct CourseView: View {
    @EnvironmentObject private var navigationController: NavigationController

    @StateObject private var viewModel: CourseViewModel
    @FeatureAvailability(.globalSearch) private var searchEnabled

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

            if (viewModel.course.numberOfAcceptedFaqs ?? 0) > 0 {
                Tab(R.string.localizable.faqTabLabel(),
                    systemImage: "questionmark.circle",
                    value: TabIdentifier.faq) {
                    TabBarIpad {
                        FaqListView(course: viewModel.course)
                    }
                }
            }

            if searchEnabled {
                Tab(value: .search, role: .search) {
                    TabBarIpad {
                        SearchTabView(courseId: viewModel.course.id)
                    }
                }
            }
        }
        .courseToolbar(title: viewModel.course.title ?? R.string.localizable.loading())
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
