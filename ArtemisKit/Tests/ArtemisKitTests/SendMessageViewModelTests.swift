import XCTest
@testable import Messages

final class SendMessageViewModelTests: XCTestCase {
    func testWriteAt() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "@"

        // then
        XCTAssertTrue(viewModel.isMemberPickerPresented)
    }

    func testWriteNumber() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "#"

        // then
        XCTAssertTrue(viewModel.isChannelPickerPresented)
    }

    func testSuppressAt() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "@"
        viewModel.isMemberPickerSuppressed = true

        // then
        XCTAssertFalse(viewModel.isMemberPickerPresented)
    }

    func testSuppressNumber() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "#"
        viewModel.isChannelPickerSuppressed = true

        // then
        XCTAssertFalse(viewModel.isChannelPickerPresented)
    }

    func testOverrideAt() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "@user "
        viewModel.text += "#channel"
        viewModel.isMemberPickerSuppressed = true

        // then
        XCTAssertTrue(viewModel.isChannelPickerPresented)
    }

    func testOverrideNumber() {
        // given
        let viewModel = SendMessageViewModel()

        // when
        viewModel.text += "#channel "
        viewModel.text += "@user"
        viewModel.isChannelPickerSuppressed = true

        // then
        XCTAssertTrue(viewModel.isMemberPickerPresented)
    }
}
