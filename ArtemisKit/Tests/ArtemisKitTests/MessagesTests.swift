import XCTest
@testable import Messages

final class SendMessageChannelPickerViewModelTests: XCTestCase {
    func testChannelNameCaseInsensitivity() async throws {
        // given
        let viewModel = SendMessageMentionChannelViewModel(
            course: .init(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging),
            messagesService: MessagesServiceStub())

        // when
        await viewModel.search(idOrName: "Annôunce")

        // then
        let channels = try XCTUnwrap(viewModel.channels.value)
        XCTAssertNotNil(channels.first)
    }
}

final class SendMessageViewModelTests: XCTestCase {
    func testWriteAt() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "@"

        // then
        XCTAssertEqual(viewModel.presentation, .memberPicker)
    }

    func testWriteNumber() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "#"

        // then
        XCTAssertEqual(viewModel.presentation, .channelPicker)
    }

    func testSuppressAt() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "@"
        viewModel.isMemberPickerSuppressed = true

        // then
        XCTAssertNotEqual(viewModel.presentation, .memberPicker)
    }

    func testSuppressNumber() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "#"
        viewModel.isChannelPickerSuppressed = true

        // then
        XCTAssertNotEqual(viewModel.presentation, .channelPicker)
    }

    func testOverrideAt() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "@user "
        viewModel.text += "#channel"
        viewModel.isMemberPickerSuppressed = true

        // then
        XCTAssertNotEqual(viewModel.presentation, .memberPicker)
    }

    func testOverrideNumber() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "#channel "
        viewModel.text += "@user"
        viewModel.isChannelPickerSuppressed = true

        // then
        XCTAssertNotEqual(viewModel.presentation, .channelPicker)
    }
}
