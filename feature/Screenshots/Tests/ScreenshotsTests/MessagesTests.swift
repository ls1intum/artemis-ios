import Dependencies
import Navigation
import SnapshotTesting
import SwiftUI
import XCTest
@testable import Messages
@testable import Screenshots

@MainActor
final class MessagesTests: XCTestCase {
    let record = true

    func testMessagesSnapshot() async throws {
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
                .navigationTitle("Basic Operators")
                .navigationBarTitleDisplayMode(.inline)
                .environmentObject(NavigationController())
        }
        assertSnapshot(of: view,
                       as: .image(layout: .device(config: .iPhone13ProMax)),
                       record: record)
    }
}
