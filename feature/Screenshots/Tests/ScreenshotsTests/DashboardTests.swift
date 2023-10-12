import Dependencies
import SnapshotTesting
import SwiftUI
import XCTest
@testable import Dashboard
@testable import Screenshots

@MainActor
final class DashboardTests: XCTestCase {
    let record = true

    func testDashboardSnapshot() {
        let viewModel = withDependencies { values in
            #warning("courseService")
//            values.courseService = CourseServiceStub()
        } operation: {
            CoursesOverviewViewModel()
        }
        let view = NavigationStack {
            CoursesOverviewView(viewModel: viewModel)
        }
        assertSnapshot(of: view,
                       as: .wait(for: 10, on: .image(layout: .device(config: .iPhone13ProMax))),
                       record: record)
    }
}
