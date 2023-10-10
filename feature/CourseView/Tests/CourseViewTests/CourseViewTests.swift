import Dependencies
import Navigation
import SnapshotTesting
import SwiftUI
import XCTest
@testable import CourseView

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
                       as: .wait(for: 10, on: .image(layout: .device(config: .iPhone13ProMax))),
                       record: record)
    }
}
