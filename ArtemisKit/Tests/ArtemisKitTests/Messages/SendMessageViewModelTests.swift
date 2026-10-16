import XCTest
import SharedModels
import UIKit
@testable import Messages

@MainActor
final class SendMessageViewModelTests: XCTestCase {
    private func makeViewModel() -> SendMessageViewModel {
        SendMessageViewModel(
            course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)),
            conversation: Conversation(conversation: Channel(id: 1))!,
            configuration: .message,
            delegate: SendMessageViewModelDelegate(
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
    func testEditorFormattingFlowsIntoCanonicalMessageText() {
        let viewModel = makeViewModel()
        viewModel.text = "hello"
        viewModel.editor.selection = NSRange(location: 0, length: 5)
        viewModel.editor.toggle(.bold)
        XCTAssertEqual(viewModel.text, "**hello**")
        viewModel.text = ""
        XCTAssertEqual(viewModel.editor.content.string, "")
    }

    func testReferencePickerReplacesOnlyTheCandidateAtCaret() {
        let viewModel = makeViewModel()
        viewModel.text = "#one then #one"
        viewModel.editor.selection = NSRange(location: 4, length: 0)
        viewModel.replace(channel: ChannelIdAndNameDTO(id: 8, name: "one"))
        XCTAssertEqual(viewModel.text, "[channel]one(8)[/channel] then #one")
    }

    func testSeparateComposersKeepIndependentSelectionAndContent() {
        let first = makeViewModel()
        let second = makeViewModel()
        first.text = "draft one"
        second.text = "draft two"
        first.editor.selection = NSRange(location: 0, length: 5)
        first.editor.toggle(.italic)
        XCTAssertEqual(first.text, "*draft* one")
        XCTAssertEqual(second.text, "draft two")
    }

    func testEditHydratesRichDocumentWithoutChangingLegacySource() {
        var message = Message(id: 42)
        message.content = "**existing** [user]Alice(alice)[/user]"
        let viewModel = SendMessageViewModel(
            course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)),
            conversation: Conversation(conversation: Channel(id: 1))!,
            configuration: .editMessage(message, {}),
            delegate: SendMessageViewModelDelegate(presentError: { _ in }, sendMessage: { _ in }))
        viewModel.performOnAppear()
        XCTAssertEqual(viewModel.text, message.content)
        XCTAssertEqual(viewModel.editor.content.string, "existing \u{fffc}")
        XCTAssertFalse(viewModel.editor.isSourceFallback)
    }
    func testToolbarTriggersOpenPickerAfterExistingWord() {
        let viewModel = makeViewModel()
        viewModel.text = "hello"
        viewModel.didTapAtButton()
        XCTAssertEqual(viewModel.conditionalPresentation, .memberPicker)
        viewModel.text = "hello"
        viewModel.didTapNumberButton()
        XCTAssertEqual(viewModel.conditionalPresentation, .channelPicker)
    }

    func testUndoImageRemovalCanRestoreCachedThumbnail() {
        let viewModel = makeViewModel()
        let path = "/api/files/photo.png"
        viewModel.insertImageMention(path: path, image: UIImage())
        let snapshot = viewModel.editor.content
        viewModel.removeImage(name: "image", path: path)
        XCTAssertTrue(viewModel.mentionedImages.isEmpty)
        viewModel.editor.accept(snapshot, selection: NSRange(location: 1, length: 0))
        XCTAssertEqual(viewModel.mentionedImages.map(\.path), [path])
    }
}
