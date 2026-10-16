import SharedModels
import XCTest
@testable import Messages

@MainActor
final class SendMessageChannelPickerViewModelTests: XCTestCase {
    func testChannelNameCaseInsensitivity() async throws {
        // given
        let viewModel = SendMessageMentionChannelViewModel(
            course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)),
            messagesService: MessagesServiceStub())

        // when
        await viewModel.search(idOrName: "Annôunce")

        // then
        let channels = try XCTUnwrap(viewModel.channels.value)
        XCTAssertNotNil(channels.first)
    }
}
