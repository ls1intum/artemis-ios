import Common
import SharedModels
import SwiftUI
import UIKit
import UserStore
import XCTest
@testable import Messages

extension SendMessageDraftTests {
    func testRetainedSeparateRepositoryDraftSurvivesAnotherComposersMatchingSend() async throws {
        for reply in [false, true] {
            let id = Int.random(in: 15_000_001...16_000_000)
            let started = expectation(description: "Matching send started")
            let finished = expectation(description: "Matching send finished")
            var finish: CheckedContinuation<Bool, Never>?
            let send: (String) async -> Bool = { value in
                XCTAssertEqual(value, "Original")
                return await withCheckedContinuation { continuation in
                    finish = continuation
                    started.fulfill()
                }
            }
            let configuration: SendMessageViewModel.Configuration = reply
                ? .answerMessage(Message(id: Int64(id)), { finished.fulfill() }) : .message
            let retained = makeDraftViewModel(repository: try MessagesRepository(), courseId: id, configuration: configuration)
            retained.performOnAppear()
            retained.text = "Original"
            retained.performOnDisappear()

            let sending = makeDraftViewModel(
                repository: try MessagesRepository(), courseId: id, configuration: configuration,
                messagesService: DraftMessagesService(answer: { value in
                    _ = await send(value)
                    return .success
                }), sendMessageWithResult: { value in
                    let accepted = await send(value)
                    finished.fulfill()
                    return accepted
                })
            sending.performOnAppear()
            sending.text = "Updated elsewhere"
            retained.performOnAppear()
            XCTAssertEqual(retained.text, "Updated elsewhere")

            sending.text = "Original"
            sending.didTapSendButton()
            await fulfillment(of: [started], timeout: 2)
            // This is new input in the retained composer, even though its repository
            // registered this same value before the other composer changed the draft.
            retained.text = "Original"
            finish?.resume(returning: true)
            await fulfillment(of: [finished], timeout: 2)

            let restored = makeDraftViewModel(repository: try MessagesRepository(), courseId: id, configuration: configuration)
            restored.performOnAppear()
            XCTAssertEqual(restored.text, "Original", "An accepted matching send must preserve the retained composer's newer input")
            retained.performOnAppear()
            XCTAssertEqual(retained.text, "Original", "Reappearing must not replace the new draft with the cleared sent value")
        }
    }

    func testRehydratedComposerCanPersistTheValueCachedByItsOlderRepository() throws {
        for reply in [false, true] {
            let id = Int.random(in: 16_000_001...17_000_000)
            let configuration: SendMessageViewModel.Configuration = reply ? .answerMessage(Message(id: Int64(id)), {}) : .message
            let retained = makeDraftViewModel(repository: try MessagesRepository(), courseId: id, configuration: configuration)
            retained.performOnAppear()
            retained.text = "Original"
            retained.performOnDisappear()

            let newer = makeDraftViewModel(repository: try MessagesRepository(), courseId: id, configuration: configuration)
            newer.performOnAppear()
            newer.text = "Updated elsewhere"
            retained.performOnAppear()
            XCTAssertEqual(retained.text, "Updated elsewhere")

            retained.text = "Original"
            let restored = makeDraftViewModel(repository: try MessagesRepository(), courseId: id, configuration: configuration)
            restored.performOnAppear()
            XCTAssertEqual(restored.text, "Original", "Replacing a refreshed draft with a cached old value must still reach disk")
        }
    }

    func testOlderSuccessfulSendPreservesANewerComposerDraft() async throws {
        for separateRepository in [false, true] {
            for reply in [false, true] {
                for replacement in ["Newer draft", "Old message"] {
                    let id = Int.random(in: 9_000_000...10_000_000)
                    let repository = try MessagesRepository()
                    let started = expectation(description: "Old send started")
                    let finished = expectation(description: "Old send completed")
                    var finish: CheckedContinuation<Bool, Never>?
                    let send: (String) async -> Bool = { value in
                        XCTAssertEqual(value, "Old message")
                        return await withCheckedContinuation { continuation in
                            finish = continuation
                            started.fulfill()
                        }
                    }
                    let configuration: SendMessageViewModel.Configuration = reply ? .answerMessage(Message(id: Int64(id)), { finished.fulfill() }) : .message
                    let older = makeDraftViewModel(repository: repository, courseId: id, configuration: configuration,
                                                   messagesService: DraftMessagesService(answer: { value in
                                                       _ = await send(value)
                                                       return .success
                                                   }), sendMessageWithResult: { value in
                                                       let accepted = await send(value)
                                                       finished.fulfill()
                                                       return accepted
                                                   })
                    older.performOnAppear()
                    older.text = "Old message"
                    older.didTapSendButton()
                    await fulfillment(of: [started], timeout: 2)
                    older.performOnDisappear()
                    let newerRepository = separateRepository ? try MessagesRepository() : repository
                    let newer = makeDraftViewModel(repository: newerRepository, courseId: id, configuration: configuration)
                    newer.performOnAppear()
                    newer.text = "Interim change"
                    newer.text = replacement
                    finish?.resume(returning: true)
                    await fulfillment(of: [finished], timeout: 2)
                    let restored = makeDraftViewModel(repository: try MessagesRepository(), courseId: id, configuration: configuration)
                    restored.performOnAppear()
                    XCTAssertEqual(restored.text, replacement, "A completed old send must not clear another composer's newer persisted input")
                    XCTAssertEqual(older.text, replacement, "A retained old composer must adopt the surviving draft when it next appears")
                }
            }
        }
    }

    func testRetainedComposerReloadsTheLatestDraftOnReappearance() throws {
        for reply in [false, true] {
            let id = Int.random(in: 10_000_001...11_000_000)
            let configuration: SendMessageViewModel.Configuration = reply ? .answerMessage(Message(id: Int64(id)), {}) : .message
            let older = makeDraftViewModel(repository: try MessagesRepository(), courseId: id, configuration: configuration)
            older.performOnAppear()
            older.text = "Original"
            older.performOnDisappear()
            let newer = makeDraftViewModel(repository: try MessagesRepository(), courseId: id, configuration: configuration)
            newer.performOnAppear()
            newer.text = "Updated elsewhere"
            older.performOnAppear()
            XCTAssertEqual(older.text, "Updated elsewhere")
            older.text += " and continued"
            let reader = makeDraftViewModel(repository: try MessagesRepository(), courseId: id, configuration: configuration)
            reader.performOnAppear()
            XCTAssertEqual(reader.text, "Updated elsewhere and continued")
        }
    }

    func testNewComposerUsingAnOlderRepositoryReadsTheLatestPersistedDraft() throws {
        for reply in [false, true] {
            let id = Int.random(in: 11_000_001...12_000_000)
            let configuration: SendMessageViewModel.Configuration = reply ? .answerMessage(Message(id: Int64(id)), {}) : .message
            let repository = try MessagesRepository()
            let older = makeDraftViewModel(repository: repository, courseId: id, configuration: configuration)
            older.performOnAppear()
            older.text = "Old snapshot"
            let newer = makeDraftViewModel(repository: try MessagesRepository(), courseId: id, configuration: configuration)
            newer.performOnAppear()
            newer.text = "Latest persisted draft"
            let reader = makeDraftViewModel(repository: repository, courseId: id, configuration: configuration)
            reader.performOnAppear()
            XCTAssertEqual(reader.text, "Latest persisted draft")
        }
    }

    func testUnchangedComposerCannotResurrectAnOlderDraft() throws {
        for replacement in ["Updated draft", ""] {
            let courseId = Int.random(in: 5_000_001...6_000_000)
            let repository = try MessagesRepository()
            let host = try XCTUnwrap(UserSessionFactory.shared.institution?.baseURL?.host())
            try repository.insertConversation(host: host, courseId: courseId, conversationId: courseId, messageDraft: "Old draft")
            let older = makeDraftViewModel(repository: repository, courseId: courseId)
            let current = makeDraftViewModel(repository: repository, courseId: courseId)
            older.performOnAppear()
            current.performOnAppear()
            current.text = replacement
            current.performOnDisappear()
            older.performOnDisappear()
            let restored = makeDraftViewModel(repository: try MessagesRepository(), courseId: courseId)
            restored.performOnAppear()
            XCTAssertEqual(restored.text, replacement, "A late disappearance must not restore the older draft")
        }
    }

    func testNativeDraftChangesAreSavedWhileComposerRemainsVisible() async throws {
        let courseId = Int.random(in: 6_000_001...7_000_000)
        let composer = makeDraftViewModel(repository: try MessagesRepository(), courseId: courseId)
        let appeared = expectation(description: "Composer appeared")
        appeared.assertForOverFulfill = false
        let controller = UIHostingController(rootView: SendMessageView(viewModel: composer)
            .onAppear { appeared.fulfill() })
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        defer { window.isHidden = true; window.rootViewController = nil }
        window.rootViewController = controller
        window.makeKeyAndVisible()
        await fulfillment(of: [appeared], timeout: 2)
        controller.view.layoutIfNeeded()
        let nativeEditor = try XCTUnwrap(findNativeEditor(in: controller.view))
        nativeEditor.insertText("Saved before leaving")
        XCTAssertEqual(composer.text, "Saved before leaving")
        let reader = makeDraftViewModel(repository: try MessagesRepository(), courseId: courseId)
        reader.performOnAppear()
        XCTAssertEqual(reader.text, "Saved before leaving")
    }

    func testNativeEditsReplaceAndDeleteARestoredDraft() async throws {
        let courseId = Int.random(in: 4_000_001...5_000_000)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        defer { window.isHidden = true; window.rootViewController = nil }
        for expected in ["Original draft", "Changed draft", ""] {
            let composer = makeDraftViewModel(repository: try MessagesRepository(), courseId: courseId)
            let appeared = expectation(description: "Composer appeared")
            let disappeared = expectation(description: "Composer disappeared")
            appeared.assertForOverFulfill = false
            disappeared.assertForOverFulfill = false
            let controller = UIHostingController(rootView: SendMessageView(viewModel: composer)
                .onAppear { appeared.fulfill() }.onDisappear { disappeared.fulfill() })
            window.rootViewController = controller
            window.makeKeyAndVisible()
            await fulfillment(of: [appeared], timeout: 2)
            controller.view.layoutIfNeeded()
            let editor = try XCTUnwrap(findNativeEditor(in: controller.view))
            editor.selectedRange = NSRange(location: 0, length: editor.attributedText.length)
            editor.insertText(expected)
            XCTAssertEqual(composer.text, expected)
            window.isHidden = true
            window.rootViewController = nil
            await fulfillment(of: [disappeared], timeout: 2)
            let restored = makeDraftViewModel(repository: try MessagesRepository(), courseId: courseId)
            restored.performOnAppear()
            XCTAssertEqual(restored.text, expected, "Native edits to a restored draft must reach disk")
        }
    }

    func testReopenedConversationDraftCanBeReplacedAndDeleted() throws {
        let courseId = Int.random(in: 2_000_000...3_000_000)
        for expected in ["First draft", "Replacement **draft**", ""] {
            do {
                let repository = try MessagesRepository()
                let composer = makeDraftViewModel(repository: repository, courseId: courseId)
                composer.performOnAppear()
                composer.text = expected
                composer.performOnDisappear()
            }
            let reader = makeDraftViewModel(repository: try MessagesRepository(), courseId: courseId)
            reader.performOnAppear()
            XCTAssertEqual(reader.text, expected, "A reopened store must contain the latest draft, including deletion")
        }
    }

    func testReopenedReplyDraftCanBeReplacedAndDeleted() throws {
        let courseId = Int.random(in: 3_000_001...4_000_000)
        let configuration = SendMessageViewModel.Configuration.answerMessage(Message(id: 365_999), {})
        for expected in ["First reply", "Replacement reply", ""] {
            do {
                let composer = makeDraftViewModel(repository: try MessagesRepository(), courseId: courseId, configuration: configuration)
                composer.performOnAppear()
                composer.text = expected
                composer.performOnDisappear()
            }
            let reader = makeDraftViewModel(repository: try MessagesRepository(), courseId: courseId, configuration: configuration)
            reader.performOnAppear()
            XCTAssertEqual(reader.text, expected)
        }
    }
}
