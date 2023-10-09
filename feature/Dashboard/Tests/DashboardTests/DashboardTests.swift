import Dependencies
import SnapshotTesting
import SwiftUI
import XCTest
@testable import Dashboard

@MainActor
final class DashboardTests: XCTestCase {
    let record = true
    
    /// Devices
    ///
    /// - iPhone 6.7"
    /// - iPhone 6.5"
    /// - iPhone 5.5" (Home button)
    /// - iPad 12.9"
    /// - iPad 12.9" (Home button)
    let devices: [(String, ViewImageConfig)] = [
        ("iPhone12ProMax", .iPhone12ProMax),
//        ("iPhoneXsMax", .iPhoneXsMax),
//        ("iPhone8Plus", .iPhone8Plus),
//        ("iPadPro12_9_6th", .iPadPro12_9),
//        ("iPadPro12_9_2nd", .iPadPro12_9),
    ]
    
    func testDashboardSnapshot() {
        #error("Work in progress")
        for (name, config) in devices {
            let view = NavigationStack {
                withDependencies { values in
                    values.courseService = CourseServiceStub()
                } operation: {
                    CoursesOverviewView(viewModel: withDependencies({ values in
                        values.courseService = CourseServiceStub()
                    }, operation: {
                        CoursesOverviewViewModel()
                    }))
                }
            }

//            let traits = config.traits.replacing(UITraitDisplayScale.self, value: 3)
//            traits.mer
//            config.traits.merge
            let traits = UITraitCollection.init(traitsFrom: [config.traits, .init(displayScale: 3)])
            var config_ = config
            config_.size = .init(width: 1290, height: 2796)
            config_.traits = traits

            assertSnapshot(of: view,
                           as: .wait(for: 10, on: .image(layout: .fixed(width: 1290, height: 2796), traits: .init(displayScale: 3))),
//                           as: .wait(for: 10, on: .image(layout: .device(config: config_), traits: .init(displayScale: 3))),
//                           size = .init(width: 428, height: 926)
//                           as: .image(layout: .device(config: config)),
                           record: record,
                           testName: name)
        }
    }
}
