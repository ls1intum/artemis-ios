import XCTest
@testable import Messages

final class MessagesRepositoryTests: XCTestCase {
    func testInsertAndUpdateAndFetch() async throws {
        // given
        let url = try XCTUnwrap(URL(string: "https://example.org"))
        let host = try XCTUnwrap(url.host())
        let courseId = 1
        let conversationId = 1
        let draft = "Hello"
        let draftUpdate = "Hello, world!"

        // when
        // - init
        let repository = try await MessagesRepository()

        await repository.insertServer(host: host)

        // - draft & override
        try await repository.insertConversation(host: host, courseId: courseId, conversationId: conversationId, draft: draft)
        try await repository.insertConversation(host: host, courseId: courseId, conversationId: conversationId, draft: draftUpdate)

        // - fetch
        let conversation = try await repository.fetchConversation(host: host, courseId: courseId, conversationId: conversationId)

        // then
        let first = try XCTUnwrap(conversation)
        XCTAssertEqual(first.draft, draftUpdate)
    }
}
