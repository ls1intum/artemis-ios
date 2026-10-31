import Common
import SharedModels
import SwiftUI
import XCTest
@testable import Messages

extension SendMessageDraftTests {
    func testSuccessfulEditsPublishTheAcceptedMessageBeforeDismissing() async throws {
        for reply in [false, true] {
            for succeeds in [false, true] {
                let finished = expectation(description: "Edit finished")
                finished.isInverted = !succeeds
                var published: BaseMessage?
                let completion = {
                    XCTAssertNotNil(published, "Update the visible message before dismissing the sheet")
                    finished.fulfill()
                }
                let configuration: SendMessageViewModel.Configuration = reply
                    ? .editAnswerMessage(AnswerMessage(id: 42), completion) : .editMessage(Message(id: 42), completion)
                let service = DraftMessagesService(answer: { _ in .loading }, editResponse: succeeds ? .success : .notStarted)
                let model = makeDraftViewModel(repository: try MessagesRepository(inMemory: true), courseId: Int.random(in: 12_000_001...13_000_000),
                                               configuration: configuration, messagesService: service,
                                               didEditMessage: { published = $0 })
                model.performOnAppear()
                model.text = "Accepted **edit**"
                model.didTapSendButton()
                if succeeds {
                    await fulfillment(of: [finished], timeout: 2)
                    XCTAssertEqual(published?.id, 42)
                    XCTAssertEqual(published?.content, "Accepted **edit**")
                    XCTAssertEqual(published is AnswerMessage, reply)
                } else {
                    await fulfillment(of: [finished], timeout: 0.05)
                    XCTAssertNil(published)
                    XCTAssertEqual(model.text, "Accepted **edit**")
                }
            }
        }
    }

    func testRetainedActionModelUsesTheCurrentBindingWhenReopeningSheets() throws {
        let repository = try MessagesRepository(inMemory: true)
        let composer = makeDraftViewModel(repository: repository, courseId: 14_000_042)
        var original = Message(id: 42)
        original.content = "Before edit"
        let actions = MessageActionsViewModel(
            conversationViewModel: ConversationViewModel(course: composer.course, conversation: composer.conversation,
                                                         messagesRepository: repository, messagesService: MessagesServiceStub(), skipLoadingData: true),
            message: .constant(.done(response: original)))
        var latest = original
        latest.content = "Accepted edit"
        latest.answers = [AnswerMessage(id: 7)]
        var state = DataState<BaseMessage>.done(response: latest)
        actions.updateMessageBinding(Binding(get: { state }, set: { state = $0 }))
        XCTAssertEqual(actions.message.value?.content, "Accepted edit", "Reopening forward/edit must use the latest text")
        XCTAssertEqual((actions.message.value as? Message)?.answers?.map(\.id), [7])
        var next = latest
        next.content = "Second edit"
        actions.message = .done(response: next)
        XCTAssertEqual(state.value?.content, "Second edit", "The refreshed binding must still publish accepted edits to its owner")
    }

    func testAcceptedEditMergesOnlyContentIntoTheLatestMatchingMessage() throws {
        var latest = Message(id: 42)
        latest.content = "Before"
        latest.answers = [AnswerMessage(id: 9)]
        latest.isSaved = true
        var accepted = Message(id: 42)
        accepted.content = "Edited"
        let merged = try XCTUnwrap(MessageActionsViewModel.mergeAcceptedEdit(accepted, into: latest) as? Message)
        XCTAssertEqual(merged.content, "Edited")
        XCTAssertEqual(merged.answers?.map(\.id), [9])
        XCTAssertTrue(try XCTUnwrap(merged.isSaved))
        var answer = AnswerMessage(id: 42)
        answer.content = "Before reply"
        answer.isSaved = true
        var editedAnswer = AnswerMessage(id: 42)
        editedAnswer.content = "Edited reply"
        let mergedAnswer = try XCTUnwrap(MessageActionsViewModel.mergeAcceptedEdit(editedAnswer, into: answer) as? AnswerMessage)
        XCTAssertEqual(mergedAnswer.content, "Edited reply")
        XCTAssertTrue(try XCTUnwrap(mergedAnswer.isSaved))
        XCTAssertNil(MessageActionsViewModel.mergeAcceptedEdit(accepted, into: nil))
        XCTAssertNil(MessageActionsViewModel.mergeAcceptedEdit(accepted, into: Message(id: 43)))
        XCTAssertNil(MessageActionsViewModel.mergeAcceptedEdit(accepted, into: answer))
    }
}
