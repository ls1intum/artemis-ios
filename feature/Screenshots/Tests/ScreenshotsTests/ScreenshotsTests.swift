import Dependencies
import Navigation
import SnapshotTesting
import SwiftUI
import XCTest
@testable import CourseView
@testable import Dashboard
@testable import Messages
@testable import Screenshots

@MainActor
final class ScreenshotsTests: XCTestCase {
    let record = true

    let configurations: [(name: String, layout: SwiftUISnapshotLayout)] = [
        ("iPhone13ProMax", .device(config: .iPhone13ProMax)),
        ("iPhone15ProMax", {
            var config = ViewImageConfig.iPhone13ProMax
            config.size = .init(width: 430, height: 932)
            return .device(config: config)
        }()),
        ("iPadPro12_9_portrait", .device(config: .iPadPro12_9(.portrait))),
    ]

    func testCoursesOverviewViewSnapshot() {
        let viewModel = withDependencies { values in
            values.courseService = CourseServiceStub()
        } operation: {
            CoursesOverviewViewModel()
        }
        let view = NavigationStack {
            CoursesOverviewView(viewModel: viewModel)
        }
            .modifier(AppStorePreview(title: "Manage all of your courses in one app"))
        for configuration in configurations {
            assertSnapshot(of: view,
                           as: .wait(for: 4, on: .image(layout: configuration.layout)),
                           named: configuration.name,
                           record: record)
        }
    }

    func testExerciseListViewSnapshot() async {
        let viewModel = withDependencies { values in
            values.courseService = CourseServiceStub()
        } operation: {
            CourseViewModel(courseId: 1)
        }
        await viewModel.loadCourse(id: 1)
        let view = NavigationStack {
            CourseView(viewModel: viewModel, courseId: 1)
                .environmentObject({ () -> NavigationController in
                    let navigationController = NavigationController()
                    navigationController.courseTab = .exercise
                    return navigationController
                }())
        }
            .modifier(AppStorePreview(title: "Always have an overview of your exercises at hand"))
        for configuration in configurations {
            assertSnapshot(of: view,
                           as: .wait(for: 1, on: .image(layout: configuration.layout)),
                           named: configuration.name,
                           record: record)
        }
    }

    func testMessagesTabViewSnapshot() async {
        let viewModel = withDependencies { values in
            values.messagesService = MessagesServiceStub()
        } operation: {
            MessagesTabViewModel(course: .init(
                id: 1,
                courseInformationSharingConfiguration: .messagingOnly))
        }
        await viewModel.loadConversations()
        let view = NavigationStack {
            MessagesTabView(viewModel: viewModel, searchText: .constant(""))
                .navigationTitle("Advanced Aerospace Engineering 🚀")
                .navigationBarTitleDisplayMode(.inline)
        }
            .modifier(AppStorePreview(title: "Communicate with students and instructors"))
        for configuration in configurations {
            assertSnapshot(of: view,
                           as: .wait(for: 1, on: .image(layout: configuration.layout)),
                           named: configuration.name,
                           record: record)
        }
    }

    func testConversationViewSnapshot() async {
        let viewModel = withDependencies { values in
            values.messagesService = MessagesServiceStub()
        } operation: {
            ConversationViewModel(
                course: .init(
                    id: 1,
                    courseInformationSharingConfiguration: .communicationAndMessaging),
                conversation: .oneToOneChat(conversation: .init(
                    type: .oneToOneChat,
                    id: 1)))
        }
        await viewModel.start()
        let view = NavigationStack {
            ConversationView(viewModel: viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .environmentObject(NavigationController())
        }
            .modifier(AppStorePreview(title: "Send and receive messages from the app"))
        for configuration in configurations {
            assertSnapshot(of: view,
                           as: .wait(for: 1, on: .image(layout: configuration.layout)),
                           named: configuration.name,
                           record: record)
        }
    }

    func testLectureDetailViewSnapshot() async {
        let viewModel = withDependencies { values in
            values.courseService = CourseServiceStub()
            values.lectureService = LectureServiceStub()
        } operation: {
            LectureDetailViewModel(courseId: 1, lectureId: 1)
        }
        await viewModel.loadLecture()
        await viewModel.loadCourse()
        let view = NavigationStack {
            LectureDetailView(viewModel: viewModel)
        }
            .modifier(AppStorePreview(title: "Directly interact with your lectures within the app"))
        for configuration in configurations {
            assertSnapshot(of: view,
                           as: .wait(for: 1, on: .image(layout: configuration.layout)),
                           named: configuration.name,
                           record: record)
        }
    }
}
