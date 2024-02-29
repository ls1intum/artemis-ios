import XCTest
@testable import Messages

final class AnyRepositoryTests: XCTestCase {
    func testRoundtrip() async throws {
        // given
        let repository = try AnyRepository()
        let draft = "Hello"

        // when
        // - a
        let conversation = ConversationModel(draft: draft)
        try await repository.insert(conversation: conversation)
        let conversations = try await repository.fetch()

        // - b

        // then
        let first = try XCTUnwrap(conversations.first)
        XCTAssertEqual(first.draft, draft)
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
