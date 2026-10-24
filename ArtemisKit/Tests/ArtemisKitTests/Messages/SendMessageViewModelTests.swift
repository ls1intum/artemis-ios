import XCTest
import SharedModels
import UIKit
import UserStore
@testable import Messages

@MainActor
final class SendMessageViewModelTests: XCTestCase {
    func testEmptyFormattingAndWhitespaceDoNotEnableSend() {
        let model = makeViewModel()
        for empty in ["", " \n ", "- ", "1. ", "> ", "```\n```"] {
            model.text = empty
            XCTAssertFalse(model.canSend, "No message body in \(empty.debugDescription)")
        }
        for message in ["Hello", "- Item", "1. Item", "> Quote", "```\ncode\n```", "[File](/api/files/file.pdf)"] {
            model.text = message
            XCTAssertTrue(model.canSend, message)
        }
    }

    func testUploadedFileNamesKeepMarkdownCharactersAndAttachmentActions() {
        for name in ["Research [final].pdf", "a*b*.pdf", "Design (2) 😀.pdf"] {
            let model = makeViewModel()
            model.insertFileMention(path: "/api/files/upload_(1).pdf", fileName: name)
            XCTAssertEqual(model.editor.attachments.map(\.name), [name])
            XCTAssertEqual(model.editor.attachments.map(\.path), ["/api/files/upload_(1).pdf"])
            let reopened = MessageEditorDocument()
            reopened.load(model.text)
            XCTAssertFalse(reopened.hasUnsupportedContent)
            XCTAssertEqual(reopened.attachments.map(\.name), [name])
        }
    }

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
        viewModel.editor.insertText("@")

        // then
        XCTAssertEqual(viewModel.conditionalPresentation, .memberPicker)
    }

    func testWriteNumber() {
        // given
        let viewModel = makeViewModel()

        // when
        viewModel.editor.insertText("#")

        // then
        XCTAssertEqual(viewModel.conditionalPresentation, .channelPicker)
    }

    func testSuppressAt() {
        // given
        let viewModel = makeViewModel()

        // when
        viewModel.editor.insertText("@")
        viewModel.isMemberPickerSuppressed = true

        // then
        XCTAssertNotEqual(viewModel.conditionalPresentation, .memberPicker)
    }

    func testSuppressNumber() {
        // given
        let viewModel = makeViewModel()

        // when
        viewModel.editor.insertText("#")
        viewModel.isChannelPickerSuppressed = true

        // then
        XCTAssertNotEqual(viewModel.conditionalPresentation, .channelPicker)
    }

    func testOverrideAt() {
        // given
        let viewModel = makeViewModel()

        // when
        viewModel.editor.insertText("@user ")
        viewModel.editor.insertText("#channel")
        viewModel.isMemberPickerSuppressed = true

        // then
        XCTAssertNotEqual(viewModel.conditionalPresentation, .memberPicker)
    }

    func testOverrideNumber() {
        // given
        let viewModel = makeViewModel()

        // when
        viewModel.editor.insertText("#channel ")
        viewModel.editor.insertText("@user")
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
        XCTAssertFalse(viewModel.editor.hasUnsupportedContent)
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
    func testUnsupportedContentBlocksSendingForEveryComposerConfiguration() async {
        let unexpectedSend = expectation(description: "Unsupported content must not be sent")
        unexpectedSend.isInverted = true
        unexpectedSend.assertForOverFulfill = false
        let source = "# Heading"
        let configurations: [SendMessageViewModel.Configuration] = [
            .message, .forwardMessage, .answerMessage(Message(id: 42), {}),
            .editMessage(Message(id: 42), {}), .editAnswerMessage(AnswerMessage(id: 43), {})
        ]
        for configuration in configurations {
            let viewModel = SendMessageViewModel(
                course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)),
                conversation: Conversation(conversation: Channel(id: 1))!,
                configuration: configuration,
                delegate: SendMessageViewModelDelegate(presentError: { _ in }, sendMessage: { _ in unexpectedSend.fulfill() }),
                messagesService: MessagesServiceStub())
            viewModel.text = source
            XCTAssertFalse(viewModel.canSend)
            viewModel.didTapSendButton()
            XCTAssertFalse(viewModel.isLoading)
            viewModel.didTapLinkButton()
            viewModel.didTapAtButton()
            viewModel.didTapNumberButton()
            viewModel.insertFileMention(path: "/api/files/file.pdf", fileName: "file")
            viewModel.insertImageMention(path: "/api/files/image.png", image: UIImage())
            XCTAssertFalse(viewModel.showsLinkEditor)
            XCTAssertNil(viewModel.conditionalPresentation)
            XCTAssertTrue(viewModel.uploadedImages.isEmpty)
            XCTAssertEqual(viewModel.text, source)
            viewModel.text = "supported"
            XCTAssertTrue(viewModel.canSend)
        }
        await fulfillment(of: [unexpectedSend], timeout: 0.1)
    }
    func testUnsupportedLoadCancelsQueuedSend() async {
        let unexpectedSend = expectation(description: "Unsupported content must not be sent by a queued task")
        unexpectedSend.isInverted = true
        let viewModel = SendMessageViewModel(
            course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)),
            conversation: Conversation(conversation: Channel(id: 1))!,
            configuration: .message,
            delegate: SendMessageViewModelDelegate(presentError: { _ in }, sendMessage: { _ in unexpectedSend.fulfill() }))
        viewModel.text = "supported"
        viewModel.didTapSendButton()
        viewModel.text = "# Heading"
        await fulfillment(of: [unexpectedSend], timeout: 0.1)
        XCTAssertEqual(viewModel.text, "# Heading")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSupportedMessageCanSendAfterUnsupportedContent() async {
        let sent = expectation(description: "Supported message sent")
        var sentText: String?
        let viewModel = SendMessageViewModel(
            course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)),
            conversation: Conversation(conversation: Channel(id: 1))!,
            configuration: .message,
            delegate: SendMessageViewModelDelegate(presentError: { _ in }, sendMessage: { text in
                sentText = text
                sent.fulfill()
            }))
        viewModel.text = "# Heading"
        viewModel.text = "hello"
        viewModel.didTapSendButton()
        await fulfillment(of: [sent], timeout: 1)
        XCTAssertEqual(sentText, "hello")
        XCTAssertEqual(viewModel.text, "")
    }
    func testDiscardUnsupportedSavedDraftOnlyClearsItsOwnContext() async throws {
        let repository = try MessagesRepository()
        let session = UserSessionFactory.shared
        let host = try XCTUnwrap(session.institution?.baseURL?.host())
        let courseId = 365_001
        let conversationId = 365_001
        let replyId = 365_101
        let configurations: [SendMessageViewModel.Configuration] = [.message, .answerMessage(Message(id: Int64(replyId)), {})]
        for (index, configuration) in configurations.enumerated() {
            try repository.insertConversation(host: host, courseId: courseId, conversationId: conversationId, messageDraft: "# Message")
            try repository.insertConversation(host: host, courseId: courseId, conversationId: 365_002, messageDraft: "Other conversation")
            try repository.insertMessage(host: host, courseId: courseId, conversationId: conversationId, messageId: replyId, answerMessageDraft: "# Reply")
            try repository.insertMessage(host: host, courseId: courseId, conversationId: conversationId, messageId: 365_102, answerMessageDraft: "Other reply")
            let sent = expectation(description: "Recovered draft can send")
            if index == 1 { sent.isInverted = true }
            let viewModel = SendMessageViewModel(
                course: CourseForOverviewDTO(course: Course(id: courseId, courseInformationSharingConfiguration: .communicationAndMessaging)),
                conversation: Conversation(conversation: Channel(id: Int64(conversationId)))!,
                configuration: configuration,
                delegate: SendMessageViewModelDelegate(presentError: { _ in }, sendMessage: { text in
                    XCTAssertEqual(text, "New message")
                    sent.fulfill()
                }),
                messagesRepository: repository, messagesService: MessagesServiceStub(), userSession: session)
            viewModel.performOnAppear()
            XCTAssertEqual(viewModel.text, index == 0 ? "# Message" : "# Reply")
            XCTAssertTrue(viewModel.canDiscardUnsupportedDraft)
            viewModel.discardUnsupportedDraft()
            XCTAssertEqual(viewModel.text, "")
            XCTAssertFalse(viewModel.editor.hasUnsupportedContent)
            XCTAssertFalse(viewModel.canDiscardUnsupportedDraft)
            XCTAssertEqual(try repository.fetchConversation(host: host, courseId: courseId, conversationId: conversationId)?.messageDraft,
                           index == 0 ? "" : "# Message")
            XCTAssertEqual(try repository.fetchMessage(host: host, courseId: courseId, conversationId: conversationId, messageId: replyId)?.answerMessageDraft,
                           index == 1 ? "" : "# Reply")
            XCTAssertEqual(try repository.fetchConversation(host: host, courseId: courseId, conversationId: 365_002)?.messageDraft, "Other conversation")
            XCTAssertEqual(try repository.fetchMessage(host: host, courseId: courseId, conversationId: conversationId, messageId: 365_102)?.answerMessageDraft, "Other reply")
            viewModel.performOnAppear()
            XCTAssertEqual(viewModel.text, "")
            viewModel.editor.insertText("New message")
            XCTAssertTrue(viewModel.canSend)
            viewModel.didTapSendButton()
            await fulfillment(of: [sent], timeout: 0.1)
        }
    }

    func testDiscardDoesNotAlterSentMessagesOrSupportedDrafts() {
        let configurations: [SendMessageViewModel.Configuration] = [
            .editMessage(Message(id: 42), {}), .editAnswerMessage(AnswerMessage(id: 43), {}), .forwardMessage
        ]
        for configuration in configurations {
            let viewModel = SendMessageViewModel(
                course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)),
                conversation: Conversation(conversation: Channel(id: 1))!, configuration: configuration,
                delegate: SendMessageViewModelDelegate(presentError: { _ in }, sendMessage: { _ in }))
            viewModel.text = "# Existing message"
            XCTAssertFalse(viewModel.canDiscardUnsupportedDraft)
            viewModel.discardUnsupportedDraft()
            XCTAssertEqual(viewModel.text, "# Existing message")
        }
        let draft = makeViewModel()
        draft.text = "Supported draft"
        XCTAssertFalse(draft.canDiscardUnsupportedDraft)
        draft.discardUnsupportedDraft()
        XCTAssertEqual(draft.text, "Supported draft")
    }
}
