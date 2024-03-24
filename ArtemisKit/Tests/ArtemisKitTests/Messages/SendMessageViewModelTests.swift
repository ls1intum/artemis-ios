import XCTest
import SharedModels
@testable import Messages

@MainActor
final class SendMessageViewModelTests: XCTestCase {
    private func makeViewModel() -> SendMessageViewModel {
        SendMessageViewModel(
            course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging),
            conversation: Conversation(conversation: Channel(id: 1))!,
            configuration: .message,
            delegate: SendMessageViewModelDelegate(
                loadMessages: {},
                presentError: { _ in },
                sendMessage: { _ in }))
    }

    func testWriteAt() {
        // given
        let viewModel = makeViewModel()

        // when
        viewModel.text += "@"

        // then
        XCTAssertEqual(viewModel.conditionalPresentation, .memberPicker)
    }

    func testWriteNumber() {
        // given
        let viewModel = makeViewModel()

        // when
        viewModel.text += "#"

        // then
        XCTAssertEqual(viewModel.conditionalPresentation, .channelPicker)
    }

    func testSuppressAt() {
        // given
        let viewModel = makeViewModel()

        // when
        viewModel.text += "@"
        viewModel.isMemberPickerSuppressed = true

        // then
        XCTAssertNotEqual(viewModel.conditionalPresentation, .memberPicker)
    }

    func testSuppressNumber() {
        // given
        let viewModel = makeViewModel()

        // when
        viewModel.text += "#"
        viewModel.isChannelPickerSuppressed = true

        // then
        XCTAssertNotEqual(viewModel.conditionalPresentation, .channelPicker)
    }

    func testOverrideAt() {
        // given
        let viewModel = makeViewModel()

        // when
        viewModel.text += "@user "
        viewModel.text += "#channel"
        viewModel.isMemberPickerSuppressed = true

        // then
        XCTAssertNotEqual(viewModel.conditionalPresentation, .memberPicker)
    }

    func testOverrideNumber() {
        // given
        let viewModel = makeViewModel()

        // when
        viewModel.text += "#channel "
        viewModel.text += "@user"
        viewModel.isChannelPickerSuppressed = true

        // then
        XCTAssertNotEqual(viewModel.conditionalPresentation, .channelPicker)
    }
}
