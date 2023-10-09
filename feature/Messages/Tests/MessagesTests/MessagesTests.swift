import Dependencies
import Navigation
import SnapshotTesting
import SwiftUI
import XCTest
@testable import Messages

@MainActor
final class MessagesTests: XCTestCase {
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

    func testMessagesSnapshot() async throws {
        #error("Work in progress")
        for (name, config) in devices {
            let viewModel = withDependencies({ values in
                values.messagesService = MessagesServiceStub()
            }, operation: {
                // Call to main actor-isolated initializer 'init(course:conversation:)' in a synchronous nonisolated context
                ConversationViewModel(
                    course: .init(
                        id: 1,
                        courseInformationSharingConfiguration: .communicationAndMessaging),
                    conversation: .oneToOneChat(conversation: .init(
                        type: .oneToOneChat,
                        id: 1)))
            })
            await viewModel.start()
            let view = NavigationStack {
                ConversationView(viewModel: viewModel)
                    .navigationTitle("Basic Operators")
                    .navigationBarTitleDisplayMode(.inline)
                    .environmentObject(NavigationController())
            }

            let messages = try XCTUnwrap(viewModel.dailyMessages.value)
            XCTAssertFalse(messages.isEmpty)

            assertSnapshot(of: view,
//                           as: .wait(for: 3, on: .image(layout: .device(config: config))),
                           as: .image(layout: .device(config: config)),
                           record: record,
                           testName: name)
        }
    }
}
