import XCTest
@testable import Messages

final class MessagesRepositoryTests: XCTestCase {
    func testRoundtrip() async throws {
        // given
        let url = try XCTUnwrap(URL(string: "https://example.org"))
        let host = try XCTUnwrap(url.host())
        let conversationId = 1
        let draft = "Hello"
        let override = "Hello, world!"

        // when
        // - init
        let repository = try await MessagesRepository()

        await repository.insertServer(host: host)

        // - draft & override
        try await repository.insertConversation(host: host, conversationId: conversationId, draft: draft)
        try await repository.insertConversation(host: host, conversationId: conversationId, draft: override)

        // - fetch
        let conversation = try await repository.fetchConversation(host: host, conversationId: conversationId)

        // then
        let first = try XCTUnwrap(conversation)
        XCTAssertEqual(first.draft, override)
    }
}
