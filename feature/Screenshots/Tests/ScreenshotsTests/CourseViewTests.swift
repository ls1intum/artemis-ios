import Dependencies
import Navigation
import SnapshotTesting
import SwiftUI
import XCTest
@testable import CourseView
@testable import Screenshots

@MainActor
final class CourseViewTests: XCTestCase {
    let record = true

    func testCourseViewSnapshot() {
        let viewModel = withDependencies { values in
            values.courseService = CourseServiceStub()
        } operation: {
            CourseViewModel(courseId: 1)
        }
        let view = NavigationStack {
            CourseView(viewModel: viewModel, courseId: 1)
                .environmentObject({ () -> NavigationController in
                    let navigationController = NavigationController()
                    navigationController.courseTab = .exercise
                    return navigationController
                }())
                .tint(.blue)
        }
        assertSnapshot(of: view,
                       as: .wait(for: 1, on: .image(layout: .device(config: .iPhone13ProMax))),
                       record: record)
    }

    func testExerciseListViewSnapshot() async {
        let viewModel = withDependencies { values in
            values.courseService = CourseServiceStub()
        } operation: {
            CourseViewModel(courseId: 1)
        }
        await viewModel.loadCourse(id: 1)
        let view = NavigationStack {
            ExerciseListView(viewModel: viewModel, searchText: .constant(""))
                .navigationTitle(viewModel.course.value?.title ?? R.string.localizable.loading())
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: .constant(""))
        }
        assertSnapshot(of: view,
                       as: .wait(for: 1, on: .image(layout: .device(config: .iPhone13ProMax))),
                       record: record)
    }
}
