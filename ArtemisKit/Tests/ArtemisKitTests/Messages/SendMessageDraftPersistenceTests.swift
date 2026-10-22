import SharedModels
import SwiftUI
import UIKit
import UserStore
import XCTest
@testable import Messages

extension SendMessageDraftTests {
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
