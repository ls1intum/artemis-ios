import XCTest
@testable import Messages

final class AnyRepositoryTests: XCTestCase {
    func testRoundtrip() async throws {
        // given
        let repository = try AnyRepository()
        let draft = "Hello"
        let override = "Hello, world!"

        // when
        // - a
        do {
            let conversation = ConversationModel(draft: draft)
            try await repository.insert(conversation: conversation)
        }

        // - b
        do {
            let conversation = ConversationModel(draft: override)
            try await repository.insert(conversation: conversation)
        }

        // - c
        let conversations = try await repository.fetch()

        // then
        let first = try XCTUnwrap(conversations.first)
        XCTAssertEqual(first.draft, override)
    }

//    func test_() async throws {
//        // given
//        let host = "artemis.cit.tum.de"
//        let file = try File()
//
//        // when
//        let institution = InstitutionModel(host: host)
//        await file.insert(institution: institution)
//        let url = try XCTUnwrap(URL(string: "https://\(host)/"))
//    }
}
