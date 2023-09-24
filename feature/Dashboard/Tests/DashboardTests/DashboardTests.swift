import SnapshotTesting
import XCTest
@testable import Dashboard

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
        ("iPhoneXsMax", .iPhoneXsMax),
        ("iPhone8Plus", .iPhone8Plus),
        ("iPadPro12_9_6th", .iPadPro12_9),
        ("iPadPro12_9_2nd", .iPadPro12_9),
    ]
    
    func testDashboardSnapshot() {
        for (name, config) in devices {
            assertSnapshot(of: CoursesOverviewView_Previews.previews,
                           as: .wait(for: 1, on: .image(layout: .device(config: config))),
                           record: record,
                           testName: name)
        }
    }
}
