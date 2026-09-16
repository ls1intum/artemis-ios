import SwiftUI
import Faq
import Common
import SharedModels
import Navigation
import Messages
import Iris
import ProfileInfo
import Search
import DesignLibrary

public struct CourseView: View {
    @EnvironmentObject private var navigationController: NavigationController
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var viewModel: CourseViewModel
    @FeatureAvailability(.globalSearch) private var searchEnabled

    private let courseId: Int

    public var body: some View {
        TabView(selection: $navigationController.courseTab) {
            if potentiallyVisibleTabs.contains(.exercise) {
                Tab(R.string.localizable.exercisesTabLabel(),
                    systemImage: "list.bullet.clipboard.fill",
                    value: TabIdentifier.exercise) {
                    TabBarIpad {
                        ExerciseTabView(viewModel: viewModel)
                    }
                }
            }

            if potentiallyVisibleTabs.contains(.lecture) {
                Tab(R.string.localizable.lectureTabLabel(),
                    systemImage: "character.book.closed.fill",
                    value: TabIdentifier.lecture) {
                    TabBarIpad {
                        LectureTabView(viewModel: viewModel,
                                       showFaqButton: !potentiallyVisibleTabs.contains(.faq))
                    }
                }
            }

            if viewModel.isMessagesVisible && potentiallyVisibleTabs.contains(.communication) {
                Tab(R.string.localizable.messagesTabLabel(),
                    systemImage: "bubble.right.fill",
                    value: TabIdentifier.communication) {
                    TabBarIpad {
                        MessagesTabView(course: viewModel.course)
                    }
                }
            }

            if viewModel.availableTabs.faq && potentiallyVisibleTabs.contains(.faq) {
                Tab(R.string.localizable.faqTabLabel(),
                    systemImage: "questionmark.circle",
                    value: TabIdentifier.faq) {
                    TabBarIpad {
                        FaqListView(course: viewModel.course)
                    }
                }
            }

            if searchEnabled && potentiallyVisibleTabs.contains(.search) {
                Tab(value: .search, role: .search) {
                    SearchTabView(courseId: viewModel.course.id,
                                  irisEnabled: viewModel.availableTabs.iris)
                    // Search tab does not use split view, so always use compact toolbar
                        .courseToolbar(title: viewModel.course.title ?? R.string.localizable.loading())
                        .environment(\.horizontalSizeClass, .compact)
                }
            }

            if viewModel.availableTabs.iris && potentiallyVisibleTabs.contains(.iris) {
                Tab("Iris", systemImage: "eyes", value: TabIdentifier.iris) {
                    TabBarIpad {
                        IrisSessionListView(course: viewModel.course)
                    }
                }
            }
        }
        .environment(\.availableTabs, viewModel.availableTabs)
        .courseToolbar(title: viewModel.course.title ?? R.string.localizable.loading())
        // Add a file and image picker here, inside the navigation it doesn't work sometimes
        .supportsFilePicker()
        .supportsImagePicker()
        .onChange(of: potentiallyVisibleTabs) {
            if !potentiallyVisibleTabs.contains(navigationController.courseTab) {
                navigationController.courseTab = potentiallyVisibleTabs.first ?? .exercise
            }
        }
    }
}

extension CourseView {
    init(course: CourseForOverviewDTO, availableTabs: CourseAvailableTabsDTO) {
        self.init(viewModel: CourseViewModel(course: course, availableTabs: availableTabs), courseId: course.id)
    }
}

private extension CourseView {
    var potentiallyVisibleTabs: [TabIdentifier] {
        var tabs = [TabIdentifier]()

        // Add tabs in "importance" order after the first 5
        if viewModel.availableTabs.iris {
            tabs.append(.iris)
        }

        if searchEnabled {
            tabs.append(.search)
        }

        if let exercises = viewModel.exercisesOverview.value {
            if !(exercises.exercises ?? []).isEmpty {
                tabs.append(.exercise)
            }
        } else {
            tabs.append(.exercise)
        }
        

        if viewModel.availableTabs.lectures {
            tabs.append(.lecture)
        }

        if viewModel.isMessagesVisible {
            tabs.append(.communication)
        }

        // Importance order -> shown if possible
        if viewModel.availableTabs.faq {
            tabs.append(.faq)
        }

        // All necessary tabs visible, but still space -> Show at least exercises/lectures (default)
        if tabs.count < 5 {
            tabs.append(.exercise)
        }
        if tabs.count < 5 {
            tabs.append(.lecture)
        }

        let tabLimit = isIpadWithTopBar ? 7 : 5

        return Array(tabs.prefix(tabLimit))
    }

    var isIpadWithTopBar: Bool {
        sizeClass == .regular && UIDevice.current.userInterfaceIdiom != .phone
    }
}
