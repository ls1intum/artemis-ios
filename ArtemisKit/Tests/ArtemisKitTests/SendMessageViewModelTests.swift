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
}
