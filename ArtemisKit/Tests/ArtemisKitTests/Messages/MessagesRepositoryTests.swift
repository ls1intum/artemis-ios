import XCTest
import UserStore
@testable import Messages

final class MessagesRepositoryTests: XCTestCase {
    func testInsertAndUpdateAndFetch() async throws {
        // given
        let url = try XCTUnwrap(URL(string: "https://example.org"))
        let host = try XCTUnwrap(url.host())
        let courseId = 1
        let conversationId = 1
        let messageDraft = "Hello"
        let messageDraftUpdate = "Hello, world!"

        // when
        // - init
        let repository = try await MessagesRepository()

        await repository.insertServer(host: host)

        // - insert & update
        try await repository.insertConversation(host: host, courseId: courseId, conversationId: conversationId, messageDraft: messageDraft)
        try await repository.insertConversation(host: host, courseId: courseId, conversationId: conversationId, messageDraft: messageDraftUpdate)

        // - fetch
        let conversation = try await repository.fetchConversation(host: host, courseId: courseId, conversationId: conversationId)

        // then
        let first = try XCTUnwrap(conversation)
        XCTAssertEqual(first.messageDraft, messageDraftUpdate)
    }

    func testCacheInvalidation() async throws {
        // given
        let url = try XCTUnwrap(URL(string: "https://example.org"))
        let host = try XCTUnwrap(url.host())
        let repository = try await MessagesRepository(timeoutInSeconds: 1)

        // when
        try await repository.insertServer(host: host)
        try await Task.sleep(for: .seconds(2))
        let server = try await repository.fetchServer(host: host)

        // then
        XCTAssertNil(server)
    }

    @MainActor
    func testOfflineMessageIsSavedBeforeEnqueueReturns() throws {
        let host = try XCTUnwrap(UserSessionFactory.shared.institution?.baseURL?.host())
        // Keep the disk-reopen assertion independent of IDs left by earlier test runs.
        let conversationId = Int.random(in: 1_000_000...Int.max)
        let source = "Queued **message \(UUID().uuidString)**"
        do {
            let repository = try MessagesRepository()
            let inserted = try repository.insertConversationOfflineMessage(host: host, courseId: conversationId, conversationId: conversationId,
                                                                           date: .now, text: source)
            XCTAssertEqual(inserted.text, source)
            XCTAssertEqual(inserted.conversation.conversationId, conversationId)
        }
        let reopened = try MessagesRepository()
        let queued = try reopened.fetchConversationOfflineMessages(host: host, courseId: conversationId, conversationId: conversationId)
        let saved = try XCTUnwrap(queued.first(where: { $0.text == source }), "A new repository must read the accepted queue entry from disk")
        defer {
            reopened.delete(conversationOfflineMessage: saved)
            reopened.save()
        }
        XCTAssertEqual(queued.count, 1)
        XCTAssertEqual(saved.conversation.conversationId, conversationId)
    }
}
