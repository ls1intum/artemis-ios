import Common
import SharedModels
import SwiftUI
import UIKit
import UserStore
import XCTest
@testable import Messages

@MainActor
final class SendMessageDraftTests: XCTestCase {
    func testRepeatedAppearanceDoesNotReplaceAnUnsavedDraft() throws {
        let repository = try MessagesRepository()
        let session = UserSessionFactory.shared
        let host = try XCTUnwrap(session.institution?.baseURL?.host())
        let courseId = 365_201
        try repository.insertConversation(host: host, courseId: courseId, conversationId: courseId, messageDraft: "")
        let viewModel = makeDraftViewModel(repository: repository, courseId: courseId)
        viewModel.performOnAppear()
        viewModel.editor.insertMarkup("Keep this **draft**")

        // A sheet/navigation transition can deliver another appearance to the same composer.
        viewModel.performOnAppear()

        XCTAssertEqual(viewModel.text, "Keep this **draft**")
    }

    func testAcceptedSendClearsPersistedDraftBeforeTheComposerDisappears() async throws {
        let repository = try MessagesRepository()
        let session = UserSessionFactory.shared
        let host = try XCTUnwrap(session.institution?.baseURL?.host())
        let courseId = 365_202
        try repository.insertConversation(host: host, courseId: courseId, conversationId: courseId, messageDraft: "Already sent")
        let sent = expectation(description: "Message accepted")
        let viewModel = makeDraftViewModel(repository: repository, courseId: courseId, sendMessage: { _ in sent.fulfill() })
        viewModel.performOnAppear()
        viewModel.didTapSendButton()
        await fulfillment(of: [sent], timeout: 1)

        XCTAssertEqual(viewModel.text, "")
        XCTAssertEqual(try repository.fetchConversation(host: host, courseId: courseId, conversationId: courseId)?.messageDraft, "")
    }

    func testQueuedSendKeepsTheTappedMessageAndPreservesNewerTyping() async throws {
        let repository = try MessagesRepository()
        let courseId = 365_203
        let session = UserSessionFactory.shared
        let host = try XCTUnwrap(session.institution?.baseURL?.host())
        try repository.insertConversation(host: host, courseId: courseId, conversationId: courseId, messageDraft: "Tapped message")
        let sent = expectation(description: "Queued message accepted")
        var sentText: String?
        let viewModel = makeDraftViewModel(repository: repository, courseId: courseId, sendMessage: { value in
            sentText = value
            sent.fulfill()
        })
        viewModel.performOnAppear()
        viewModel.didTapSendButton()
        viewModel.text = "Newer draft"
        await fulfillment(of: [sent], timeout: 1)

        XCTAssertEqual(sentText, "Tapped message")
        XCTAssertEqual(viewModel.text, "Newer draft")
        XCTAssertEqual(try repository.fetchConversation(host: host, courseId: courseId, conversationId: courseId)?.messageDraft, "Newer draft")
    }

    func testDraftSurvivesLeavingAndRecreatingTheRepository() throws {
        let courseId = 365_204
        let source = "**Draft** [user]Alice(alice)[/user]"
        do {
            let repository = try MessagesRepository()
            let viewModel = makeDraftViewModel(repository: repository, courseId: courseId)
            viewModel.performOnAppear()
            viewModel.text = source
            viewModel.performOnDisappear()
        }

        // A new container reads the saved store, not the original context's registered objects.
        let reopened = try MessagesRepository()
        let restored = makeDraftViewModel(repository: reopened, courseId: courseId)
        restored.performOnAppear()
        XCTAssertEqual(restored.text, source)
        XCTAssertEqual(restored.editor.content.string, "Draft \u{fffc}")
    }

    func testConversationAndThreadDraftsRemainIndependentAcrossNavigation() throws {
        let courseId = 365_205
        let repository = try MessagesRepository()
        let contexts: [(Int, SendMessageViewModel.Configuration, String)] = [
            (courseId, .message, "Conversation draft"),
            (courseId + 1, .message, "Other conversation"),
            (courseId, .answerMessage(Message(id: 365_305), {}), "First thread reply"),
            (courseId, .answerMessage(Message(id: 365_306), {}), "Second thread reply")
        ]
        for (conversationId, configuration, draft) in contexts {
            let composer = makeDraftViewModel(repository: repository, courseId: courseId,
                                              conversationId: conversationId, configuration: configuration)
            composer.performOnAppear()
            composer.text = draft
            composer.performOnDisappear()
        }
        let reopened = try MessagesRepository()
        for (conversationId, configuration, draft) in contexts {
            let composer = makeDraftViewModel(repository: reopened, courseId: courseId,
                                              conversationId: conversationId, configuration: configuration)
            composer.performOnAppear()
            XCTAssertEqual(composer.text, draft)
        }
    }

    func testEditingAndForwardingDoNotOverwritePersistedDrafts() throws {
        let repository = try MessagesRepository()
        let courseId = 365_206
        let host = try XCTUnwrap(UserSessionFactory.shared.institution?.baseURL?.host())
        try repository.insertConversation(host: host, courseId: courseId, conversationId: courseId, messageDraft: "Conversation draft")
        try repository.insertMessage(host: host, courseId: courseId, conversationId: courseId, messageId: 365_307, answerMessageDraft: "Reply draft")
        let configurations: [SendMessageViewModel.Configuration] = [
            .editMessage(Message(id: 365_307), {}), .editAnswerMessage(AnswerMessage(id: 365_308), {}), .forwardMessage
        ]
        for configuration in configurations {
            let composer = makeDraftViewModel(repository: repository, courseId: courseId, configuration: configuration)
            composer.performOnAppear()
            composer.text = "Unfinished change"
            composer.performOnDisappear()
        }
        XCTAssertEqual(try repository.fetchConversation(host: host, courseId: courseId, conversationId: courseId)?.messageDraft, "Conversation draft")
        XCTAssertEqual(try repository.fetchMessage(host: host, courseId: courseId, conversationId: courseId, messageId: 365_307)?.answerMessageDraft, "Reply draft")
    }

    func testSuccessfulReplyClearsSavedDraftBeforeReloadingTheThread() async throws {
        let repository = try MessagesRepository()
        let courseId = 365_207
        let messageId = 365_309
        let host = try XCTUnwrap(UserSessionFactory.shared.institution?.baseURL?.host())
        try repository.insertMessage(host: host, courseId: courseId, conversationId: courseId, messageId: messageId, answerMessageDraft: "Sent reply")
        let reloaded = expectation(description: "Thread reloaded")
        let composer = makeDraftViewModel(
            repository: repository, courseId: courseId,
            configuration: .answerMessage(Message(id: Int64(messageId)), {
                XCTAssertEqual(try? repository.fetchMessage(host: host, courseId: courseId, conversationId: courseId, messageId: messageId)?.answerMessageDraft, "")
                reloaded.fulfill()
            }), messagesService: DraftMessagesService(answer: { _ in .success }))
        composer.performOnAppear()
        composer.didTapSendButton()
        await fulfillment(of: [reloaded], timeout: 1)
        XCTAssertEqual(composer.text, "")
    }

    func testFailedReplyPreservesNewerTypingOnDisk() async throws {
        let repository = try MessagesRepository()
        let courseId = 365_208
        let messageId = 365_310
        let host = try XCTUnwrap(UserSessionFactory.shared.institution?.baseURL?.host())
        try repository.insertMessage(host: host, courseId: courseId, conversationId: courseId, messageId: messageId, answerMessageDraft: "Failed reply")
        let started = expectation(description: "Reply request started")
        let failed = expectation(description: "Reply failure presented")
        var finish: CheckedContinuation<NetworkResponse, Never>?
        let service = DraftMessagesService(answer: { value in
            XCTAssertEqual(value, "Failed reply")
            return await withCheckedContinuation { continuation in
                finish = continuation
                started.fulfill()
            }
        })
        let composer = makeDraftViewModel(repository: repository, courseId: courseId,
                                          configuration: .answerMessage(Message(id: Int64(messageId)), {}), messagesService: service,
                                          presentError: { _ in failed.fulfill() })
        composer.performOnAppear()
        composer.didTapSendButton()
        await fulfillment(of: [started], timeout: 1)
        composer.text = "Newer reply draft"
        finish?.resume(returning: .failure(error: NSError(domain: "DraftTests", code: 1)))
        await fulfillment(of: [failed], timeout: 1)
        XCTAssertFalse(composer.isLoading)
        XCTAssertEqual(composer.text, "Newer reply draft")
        XCTAssertEqual(try repository.fetchMessage(host: host, courseId: courseId, conversationId: courseId, messageId: messageId)?.answerMessageDraft, "Newer reply draft")
    }

    func testRejectedEnqueueKeepsNewerDraftInsteadOfClearingIt() async throws {
        let repository = try MessagesRepository()
        let courseId = 365_209
        let host = try XCTUnwrap(UserSessionFactory.shared.institution?.baseURL?.host())
        try repository.insertConversation(host: host, courseId: courseId, conversationId: courseId, messageDraft: "Rejected message")
        let rejected = expectation(description: "Queue rejected message")
        let composer = makeDraftViewModel(repository: repository, courseId: courseId, sendMessageWithResult: { value in
            XCTAssertEqual(value, "Rejected message")
            rejected.fulfill()
            return false
        })
        composer.performOnAppear()
        composer.didTapSendButton()
        composer.text = "Newer draft"
        await fulfillment(of: [rejected], timeout: 1)
        XCTAssertEqual(composer.text, "Newer draft")
        XCTAssertEqual(try repository.fetchConversation(host: host, courseId: courseId, conversationId: courseId)?.messageDraft, "Newer draft")
    }

    func testSuccessfulReplyPreservesImagesAddedWhileSending() async throws {
        let repository = try MessagesRepository()
        let courseId = 365_210
        let messageId = 365_311
        let host = try XCTUnwrap(UserSessionFactory.shared.institution?.baseURL?.host())
        try repository.insertMessage(host: host, courseId: courseId, conversationId: courseId, messageId: messageId, answerMessageDraft: "Sent reply")
        let started = expectation(description: "Reply request started")
        let completed = expectation(description: "Reply completed")
        var finish: CheckedContinuation<NetworkResponse, Never>?
        let service = DraftMessagesService(answer: { _ in
            await withCheckedContinuation { continuation in
                finish = continuation
                started.fulfill()
            }
        })
        let composer = makeDraftViewModel(repository: repository, courseId: courseId,
                                          configuration: .answerMessage(Message(id: Int64(messageId)), { completed.fulfill() }),
                                          messagesService: service)
        composer.performOnAppear()
        composer.didTapSendButton()
        await fulfillment(of: [started], timeout: 1)
        let path = "/api/files/new-draft.png"
        composer.text = "New reply "
        composer.insertImageMention(path: path, image: UIImage())
        let newerDraft = composer.text
        finish?.resume(returning: .success)
        await fulfillment(of: [completed], timeout: 1)
        XCTAssertEqual(composer.text, newerDraft)
        XCTAssertNotNil(composer.uploadedImages[path])
        XCTAssertEqual(try repository.fetchMessage(host: host, courseId: courseId, conversationId: courseId, messageId: messageId)?.answerMessageDraft, newerDraft)
    }

    func testCanceledQueuedSendPersistsTheClearedDraft() async throws {
        let repository = try MessagesRepository()
        let courseId = 365_211
        let host = try XCTUnwrap(UserSessionFactory.shared.institution?.baseURL?.host())
        try repository.insertConversation(host: host, courseId: courseId, conversationId: courseId, messageDraft: "Canceled message")
        let unexpectedSend = expectation(description: "Canceled send must not reach the queue")
        unexpectedSend.isInverted = true
        let composer = makeDraftViewModel(repository: repository, courseId: courseId, sendMessage: { _ in unexpectedSend.fulfill() })
        composer.performOnAppear()
        composer.didTapSendButton()
        composer.text = ""
        await fulfillment(of: [unexpectedSend], timeout: 0.1)
        XCTAssertFalse(composer.isLoading)
        XCTAssertEqual(try repository.fetchConversation(host: host, courseId: courseId, conversationId: courseId)?.messageDraft, "")
    }

    func testHostedComposerSavesNativeTypingAndRestoresOnReentry() async throws {
        let repository = try MessagesRepository()
        let courseId = 365_212
        let host = try XCTUnwrap(UserSessionFactory.shared.institution?.baseURL?.host())
        try repository.insertConversation(host: host, courseId: courseId, conversationId: courseId, messageDraft: "")
        let composer = makeDraftViewModel(repository: repository, courseId: courseId)
        let appeared = expectation(description: "Original composer appeared")
        let disappeared = expectation(description: "Original composer disappeared")
        appeared.assertForOverFulfill = false
        disappeared.assertForOverFulfill = false
        let controller = UIHostingController(rootView: SendMessageView(viewModel: composer)
            .onAppear { appeared.fulfill() }
            .onDisappear { disappeared.fulfill() })
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
        } else {
            // The Swift package test runner has no application window scene.
            window = UIWindow()
        }
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let previousKeyWindow = window.windowScene?.windows.first(where: \.isKeyWindow)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousKeyWindow?.makeKeyAndVisible()
        }
        await fulfillment(of: [appeared], timeout: 2)
        controller.view.layoutIfNeeded()
        let nativeEditor = try XCTUnwrap(findNativeEditor(in: controller.view))
        nativeEditor.insertText("Typed in the native editor")
        XCTAssertEqual(composer.text, "Typed in the native editor")
        window.isHidden = true
        window.rootViewController = nil
        await fulfillment(of: [disappeared], timeout: 2)

        // Recreate both the storage context and the SwiftUI composer. Its own onAppear must restore the native field.
        let reopened = try MessagesRepository()
        let restored = makeDraftViewModel(repository: reopened, courseId: courseId)
        XCTAssertEqual(restored.text, "")
        let reappeared = expectation(description: "Restored composer appeared")
        reappeared.assertForOverFulfill = false
        let restoredController = UIHostingController(rootView: SendMessageView(viewModel: restored)
            .onAppear { reappeared.fulfill() })
        window.rootViewController = restoredController
        window.makeKeyAndVisible()
        await fulfillment(of: [reappeared], timeout: 2)
        restoredController.view.layoutIfNeeded()
        XCTAssertEqual(restored.text, "Typed in the native editor")
        let restoredEditor = try XCTUnwrap(findNativeEditor(in: restoredController.view))
        XCTAssertEqual(restoredEditor.text, "Typed in the native editor")
    }
}

// Shared by the draft lifecycle and persistence regression tests.
@MainActor
func findNativeEditor(in view: UIView) -> MessageComposerTextView? {
    if let editor = view as? MessageComposerTextView { return editor }
    for child in view.subviews {
        if let editor = findNativeEditor(in: child) { return editor }
    }
    return nil
}

@MainActor
func makeDraftViewModel(
    repository: MessagesRepository,
    courseId: Int,
    conversationId: Int? = nil,
    configuration: SendMessageViewModel.Configuration = .message,
    messagesService: MessagesService = MessagesServiceStub(),
    presentError: @escaping (UserFacingError) -> Void = { _ in },
    sendMessage: @escaping (String) async -> Void = { _ in },
    sendMessageWithResult: ((String) async -> Bool)? = nil
) -> SendMessageViewModel {
    let delegate: SendMessageViewModelDelegate
    if let sendMessageWithResult {
        delegate = SendMessageViewModelDelegate(presentError: presentError, sendMessageWithResult: sendMessageWithResult)
    } else {
        delegate = SendMessageViewModelDelegate(presentError: presentError, sendMessage: sendMessage)
    }
    return SendMessageViewModel(
        course: CourseForOverviewDTO(course: Course(id: courseId, courseInformationSharingConfiguration: .communicationAndMessaging)),
        conversation: Conversation(conversation: Channel(id: Int64(conversationId ?? courseId)))!,
        configuration: configuration,
        delegate: delegate,
        messagesRepository: repository, messagesService: messagesService, userSession: UserSessionFactory.shared)
}

private struct DraftMessagesService: MessagesService {
    let answer: (String) async -> NetworkResponse

    func getConversations(for courseId: Int) async -> DataState<[Conversation]> { .loading }
    func updateIsConversationFavorite(for courseId: Int, and conversationId: Int64, isFavorite: Bool) async -> NetworkResponse { .loading }
    func updateIsConversationMuted(for courseId: Int, and conversationId: Int64, isMuted: Bool) async -> NetworkResponse { .loading }
    func updateIsConversationHidden(for courseId: Int, and conversationId: Int64, isHidden: Bool) async -> NetworkResponse { .loading }
    func getMessages(for courseId: Int, and conversationId: Int64, filter: MessageRequestFilter, page: Int) async -> DataState<[Message]> { .loading }
    func searchMessages(for courseId: Int, channelIds: [Int64], searchTerm: String) async -> DataState<[Message]> { .loading }
    func getMessage(with messageId: Int64, for courseId: Int, and conversationId: Int64) async -> DataState<Message> { .loading }
    func sendMessage(for courseId: Int, conversation: Conversation, content: String, hasForwardedMessages: Bool?) async -> DataState<Message> { .loading }
    func sendAnswerMessage(for courseId: Int, message: Message, content: String) async -> NetworkResponse { await answer(content) }
    func uploadFile(for courseId: Int, and conversationId: Int64, file: Data, filename: String, mimeType: String) async -> DataState<String> { .loading }
    func deleteMessage(for courseId: Int, messageId: Int64) async -> NetworkResponse { .loading }
    func deleteAnswerMessage(for courseId: Int, anserMessageId: Int64) async -> NetworkResponse { .loading }
    func updateMessageDisplayPriority(for courseId: Int64, messageId: Int64, displayPriority: DisplayPriority) async -> DataState<any BaseMessage> { .loading }
    func editMessage(for courseId: Int, message: Message) async -> NetworkResponse { .loading }
    func editAnswerMessage(for courseId: Int, answerMessage: AnswerMessage) async -> NetworkResponse { .loading }
    func addReactionToAnswerMessage(for courseId: Int, answerMessage: AnswerMessage, emojiId: String) async -> NetworkResponse { .loading }
    func addReactionToMessage(for courseId: Int, message: Message, emojiId: String) async -> NetworkResponse { .loading }
    func removeReactionFromMessage(for courseId: Int, reaction: Reaction) async -> NetworkResponse { .loading }
    func getChannelsOverview(for courseId: Int) async -> DataState<[Channel]> { .loading }
    func getChannelsPublicOverview(for courseId: Int) async -> DataState<[ChannelIdAndNameDTO]> { .loading }
    func addMembersToChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> NetworkResponse { .loading }
    func removeMembersFromChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> NetworkResponse { .loading }
    func addMembersToGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> NetworkResponse { .loading }
    func removeMembersFromGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> NetworkResponse { .loading }
    func createChannel(for courseId: Int, name: String, description: String?, traits: ConversationTraits) async -> DataState<Channel> { .loading }
    func searchForUsers(for courseId: Int, searchText: String) async -> DataState<[ConversationUser]> { .loading }
    func createGroupChat(for courseId: Int, usernames: [String]) async -> DataState<GroupChat> { .loading }
    func createOneToOneChat(for courseId: Int, username: String) async -> DataState<OneToOneChat> { .loading }
    func createOneToOneChat(for courseId: Int, userId: Int) async -> DataState<OneToOneChat> { .loading }
    func getMembersOfConversation(for courseId: Int, conversationId: Int64, page: Int) async -> DataState<[ConversationUser]> { .loading }
    func archiveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse { .loading }
    func unarchiveChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse { .loading }
    func editConversation(for courseId: Int, conversation: Conversation, newName: String?, newTopic: String?, newDescription: String?) async -> DataState<Conversation> { .loading }
    func getUnresolvedChannelIds(for courseId: Int, and channelIds: [Int64]) async -> DataState<[Int64]> { .loading }
    func deleteChannel(for courseId: Int, channelId: Int64) async -> NetworkResponse { .loading }
    func toggleChannelPrivacy(for courseId: Int, channelId: Int64) async -> NetworkResponse { .loading }
    func addSavedPost(with postId: Int64, of type: PostType) async -> NetworkResponse { .loading }
    func getSavedPosts(for courseId: Int, status: SavedPostStatus) async -> DataState<[SavedPostDTO]> { .loading }
    func updateSavedPostStatus(for postId: Int64, with type: PostType, status: SavedPostStatus) async -> NetworkResponse { .loading }
    func deleteSavedPost(with postId: Int64, of type: PostType) async -> NetworkResponse { .loading }
    func getForwardedMessages(for postIds: [Int64], courseId: Int) async -> DataState<[ForwardedMessagesGroupDTO]> { .loading }
    func forwardMessage(sourceId: Int64, sourceType: PostType, destinationId: Int64) async -> DataState<ForwardedMessageDTO> { .loading }
}
