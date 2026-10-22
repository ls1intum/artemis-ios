import SwiftUI
import UIKit
import XCTest
@testable import Messages

@MainActor
final class MessageEditorNativeIntegrationTests: XCTestCase {
    func testNativeFormattingMenuRetainsSystemActionsAndSerializesSelectedFormatting() async throws {
        let document = MessageEditorDocument()
        document.load("Hello")
        let (host, window) = try await host(document)
        defer { window.isHidden = true }
        let view = try XCTUnwrap(findEditor(host.view))
        let coordinator = try XCTUnwrap(view.delegate as? MessageRichTextEditor.Coordinator)
        let copy = UIAction(title: "Copy") { _ in }
        let menu = try XCTUnwrap(coordinator.textView(view, editMenuForTextInRanges: [NSValue(range: NSRange(location: 0, length: 5))], suggestedActions: [copy]))
        XCTAssertTrue(menu.children.first === copy)
        let formats = try XCTUnwrap(menu.children.last as? UIMenu)
        XCTAssertEqual(formats.children.count, 5)
        let bold = try XCTUnwrap(formats.children.first as? UIAction)
        UIButton(primaryAction: bold).sendActions(for: .touchUpInside)
        XCTAssertEqual(document.markdown, "**Hello**")
        XCTAssertTrue(MessageEditorDocument.style(view.attributedText.attributes(at: 0, effectiveRange: nil)).contains(.bold))
    }

    func testCodeTypingDisablesAutomaticTextSubstitutionsAndRestoresOrdinaryTraits() async throws {
        let document = MessageEditorDocument()
        let (host, window) = try await host(document)
        defer { window.isHidden = true }
        let view = try XCTUnwrap(findEditor(host.view))
        document.toggle(.code)
        await updateLayout(host)
        XCTAssertEqual(view.autocorrectionType, .no)
        XCTAssertEqual(view.autocapitalizationType, .none)
        XCTAssertEqual(view.smartQuotesType, .no)
        XCTAssertEqual(view.smartDashesType, .no)
        document.toggle(.code)
        await updateLayout(host)
        XCTAssertEqual(view.autocorrectionType, .default)
        XCTAssertEqual(view.autocapitalizationType, .sentences)
        document.toggleBlock(.codeBlock)
        await updateLayout(host)
        XCTAssertEqual(view.autocorrectionType, .no)
        XCTAssertEqual(view.autocapitalizationType, .none)
    }

    func testToolbarStyleAppliesBeforeAnImmediateNativeKeystroke() async throws {
        let document = MessageEditorDocument()
        document.load("Before ")
        let (host, window) = try await host(document)
        defer { window.isHidden = true }
        let view = try XCTUnwrap(findEditor(host.view))
        document.toggle(.code)
        // Deliberately do not wait for a SwiftUI rendering pass after the toolbar action.
        XCTAssertTrue(MessageEditorDocument.style(view.typingAttributes).contains(.code))
        view.insertText("value")
        (view.delegate as? MessageRichTextEditor.Coordinator)?.textViewDidChange(view)
        XCTAssertEqual(document.markdown, "Before `value`")
        document.toggle(.code)
        view.insertText(" plain")
        (view.delegate as? MessageRichTextEditor.Coordinator)?.textViewDidChange(view)
        XCTAssertEqual(document.markdown, "Before `value` plain")
    }

    func testNativeMenuDoesNotCombineDisjointSelections() {
        let document = MessageEditorDocument()
        document.load("Hello world")
        let parent = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false), expanded: false)
        let ranges = [NSValue(range: NSRange(location: 0, length: 5)), NSValue(range: NSRange(location: 6, length: 5))]
        XCTAssertNil(parent.makeCoordinator().textView(UITextView(), editMenuForTextInRanges: ranges, suggestedActions: []))
    }

    func testReusingNativeViewRebindsDocumentAndEditHook() async throws {
        let first = MessageEditorDocument()
        first.load("First")
        let (host, window) = try await host(first)
        defer { window.isHidden = true }
        let original = try XCTUnwrap(findEditor(host.view))
        let second = MessageEditorDocument()
        second.load("Second")
        host.rootView = EditorHarness(document: second)
        let updated = expectation(description: "Reused native editor updated")
        DispatchQueue.main.async { host.view.layoutIfNeeded(); updated.fulfill() }
        await fulfillment(of: [updated], timeout: 2)
        _ = host.sizeThatFits(in: CGSize(width: 320, height: 600))
        host.view.layoutIfNeeded()
        let reused = try XCTUnwrap(findEditor(host.view))
        XCTAssertTrue(original === reused)
        XCTAssertTrue(reused.document === second)
        XCTAssertNil(first.applyEdit)
        XCTAssertNil(first.applyTypingAttributes)
        second.insertText(" draft")
        XCTAssertEqual(reused.text, "Second draft")
        XCTAssertEqual(first.markdown, "First")
        XCTAssertEqual(reused.document?.plainText(in: NSRange(location: 0, length: reused.attributedText.length)), "Second draft")
    }

    func testNativeReturnContinuesToolbarList() async throws {
        let document = MessageEditorDocument()
        let (host, window) = try await host(document)
        defer { window.isHidden = true }
        let view = try XCTUnwrap(findEditor(host.view))
        document.toggleBlock(.bulletList)
        view.insertText("First")
        // Hardware/software keyboard replacement routes through shouldChange; insertText alone bypasses it.
        let coordinator = try XCTUnwrap(view.delegate as? MessageRichTextEditor.Coordinator)
        if coordinator.textView(view, shouldChangeTextIn: view.selectedRange, replacementText: "\n") { view.insertText("\n") }
        view.insertText("Second")
        XCTAssertEqual(document.markdown, "- First\n- Second")
        XCTAssertEqual(view.text, "• First\n• Second")
    }

    func testCompletionsKeepExpandedEditorWithinSmallHeightBudget() {
        let document = MessageEditorDocument()
        document.load(String(repeating: "line\n", count: 20) + "@a")
        let host = UIHostingController(rootView: MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false),
                                                                       expanded: true, showsCompletions: true))
        XCTAssertLessThanOrEqual(host.sizeThatFits(in: CGSize(width: 320, height: 600)).height, 80)
    }

    private func host(_ document: MessageEditorDocument) async throws -> (UIHostingController<EditorHarness>, UIWindow) {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = scene.map(UIWindow.init(windowScene:)) ?? UIWindow()
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let appeared = expectation(description: "Native editor appeared")
        let host = UIHostingController(rootView: EditorHarness(document: document, appeared: { appeared.fulfill() }))
        window.rootViewController = host
        window.makeKeyAndVisible()
        await fulfillment(of: [appeared], timeout: 2)
        host.view.layoutIfNeeded()
        return (host, window)
    }

    private func updateLayout(_ host: UIHostingController<EditorHarness>) async {
        let updated = expectation(description: "Editor traits updated")
        DispatchQueue.main.async { host.view.layoutIfNeeded(); updated.fulfill() }
        await fulfillment(of: [updated], timeout: 2)
    }

    private func findEditor(_ view: UIView) -> MessageComposerTextView? {
        if let editor = view as? MessageComposerTextView { return editor }
        return view.subviews.lazy.compactMap(findEditor).first
    }
}

private struct EditorHarness: View {
    let document: MessageEditorDocument
    var appeared: () -> Void = {}

    var body: some View {
        MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false), expanded: false)
            .onAppear(perform: appeared)
    }
}
