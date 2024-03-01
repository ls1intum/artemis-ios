import XCTest
@testable import Messages

final class ConversationRepositoryTests: XCTestCase {
    func testRoundtrip() async throws {
        // given
        let repository = try await ConversationRepository()
        let remoteId = 1
        let draft = "Hello"
        let override = "Hello, world!"

        // when
        // - draft
        do {
            let conversation = ConversationModel(remoteId: remoteId, draft: draft)
            try await repository.insert(conversation: conversation)
        }

        // - override
        do {
            let conversation = ConversationModel(remoteId: remoteId, draft: override)
            try await repository.insert(conversation: conversation)
        }

        // - fetch
        let conversations = try await repository.fetch(remoteId: remoteId)

        // then
        let first = try XCTUnwrap(conversations.first)
        XCTAssertEqual(first.draft, override)
    }
}
