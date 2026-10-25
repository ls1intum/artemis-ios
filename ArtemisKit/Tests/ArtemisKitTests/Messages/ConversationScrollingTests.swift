import SharedModels
import XCTest
@testable import Messages

@MainActor
final class ConversationScrollingTests: XCTestCase {
    func testLoadingEarlierMessagesDoesNotReplayNewMessageScroll() async {
        let viewModel = ConversationViewModel(
            course: MessagesServiceStub.course,
            conversation: MessagesServiceStub.conversation,
            messagesService: MessagesServiceStub(),
            skipLoadingData: true)
        viewModel.messages = [.message(MessagesServiceStub.reply)]
        viewModel.shouldScrollToId = MessagesServiceStub.reply.id.description

        await viewModel.loadEarlierMessages()

        XCTAssertNil(viewModel.shouldScrollToId, "Prepending history must keep the reader's position instead of scrolling to a stale incoming message")
        XCTAssertTrue(viewModel.messages.contains(.of(id: MessagesServiceStub.message.id)))
    }
}
