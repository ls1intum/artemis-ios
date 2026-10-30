import Common
import SharedModels
import XCTest
@testable import Messages

final class MessageObservationSnapshotTests: XCTestCase {
    func testUnchangedLoadingDoesNotTriggerAnotherObservation() {
        XCTAssertTrue(observationEquals(.loading, .loading))
    }

    func testUnchangedFailureDoesNotTriggerAnotherObservation() {
        let error = UserFacingError(title: "Could not load message")
        XCTAssertTrue(observationEquals(.failure(error: error), .failure(error: error)))
    }

    func testUnchangedMessageDoesNotTriggerAnotherObservation() {
        let message = Message(id: 42)
        XCTAssertTrue(observationEquals(.done(response: message), .done(response: message)))
    }

    func testReactionEmojiChangeWithSameReactionIDIsObserved() {
        var original = Message(id: 42)
        original.reactions = [Reaction(id: 1, emojiId: "heart")]
        var updated = original
        updated.reactions = [Reaction(id: 1, emojiId: "grin")]
        XCTAssertFalse(observationEquals(.done(response: original), .done(response: updated)))
    }

    func testAnswerResolutionChangeIsObserved() {
        var original = AnswerMessage(id: 43)
        original.resolvesPost = false
        var updated = original
        updated.resolvesPost = true
        XCTAssertFalse(observationEquals(.done(response: original), .done(response: updated)))
    }

    func testAuthorRoleChangeIsObserved() {
        var original = Message(id: 42)
        original.authorRole = .user
        var updated = original
        updated.authorRole = .instructor
        XCTAssertFalse(observationEquals(.done(response: original), .done(response: updated)))
    }

    func testLoadingAfterLoadedMessageIsObserved() {
        XCTAssertFalse(observationEquals(.done(response: Message(id: 42)), .loading))
    }

    private func observationEquals(_ lhs: DataState<BaseMessage>, _ rhs: DataState<BaseMessage>) -> Bool {
        MessageObservationSnapshot(lhs) == MessageObservationSnapshot(rhs)
    }
}
