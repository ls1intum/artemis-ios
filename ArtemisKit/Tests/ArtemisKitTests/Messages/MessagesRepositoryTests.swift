import XCTest
@testable import Messages

final class MessagesRepositoryTests: XCTestCase {
    func testRoundtrip() async throws {
        // given
        let url = try XCTUnwrap(URL(string: "https://example.org"))
        let host = try XCTUnwrap(url.host())
        let remoteId = 1
        let draft = "Hello"
        let override = "Hello, world!"

        // when
        // - init
        let repository = try await MessagesRepository()

        await repository.insertServer(host: host)

        // - draft & override
        try await repository.insertConversation(host: host, remoteId: remoteId, draft: draft)
        try await repository.insertConversation(host: host, remoteId: remoteId, draft: override)

        // - fetch
        let conversation = try await repository.fetchConversation(host: host, remoteId: remoteId)

        // then
        let first = try XCTUnwrap(conversation)
        XCTAssertEqual(first.draft, override)
    }
}
