import SwiftUI
import UIKit
import XCTest
@testable import Messages

@MainActor
final class MessageEditorNativeIntegrationTests: XCTestCase {
    func testEveryInlineStyleCombinationSurvivesNativeTypingAndReopening() async throws {
        let document = MessageEditorDocument()
        let (controller, window) = try await host(document)
        defer { window.isHidden = true }
        let view = try XCTUnwrap(findEditor(controller.view))
        let styles: [MessageEditorStyle] = [.bold, .italic, .underline, .strikethrough, .code]
        for mask in 0..<32 {
            document.load("Hello 😀")
            await updateLayout(controller)
            document.selection = NSRange(location: 0, length: document.content.length)
            let expected = MessageEditorStyle(rawValue: mask)
            for style in styles where expected.contains(style) { document.toggle(style) }
            XCTAssertEqual(document.activeStyle, expected, "Selected style combination \(mask)")
            XCTAssertEqual(view.attributedText.string, "Hello 😀")
            let reopened = MessageEditorDocument()
            reopened.load(document.markdown)
            XCTAssertFalse(reopened.hasUnsupportedContent, "Combination \(mask): \(document.markdown)")
            XCTAssertEqual(reopened.content.string, "Hello 😀")
            reopened.selection = NSRange(location: 0, length: reopened.content.length)
            XCTAssertEqual(reopened.activeStyle, expected)
            view.selectedRange = NSRange(location: document.content.length, length: 0)
            (view.delegate as? MessageRichTextEditor.Coordinator)?.textViewDidChangeSelection(view)
            view.insertText("!")
            XCTAssertEqual(document.content.string, "Hello 😀!")
            XCTAssertEqual(MessageEditorDocument.style(view.attributedText.attributes(at: view.attributedText.length - 1, effectiveRange: nil)), expected)
        }
    }

    func testSequentialNativeTypingKeepsEveryCharacterAcrossSwiftUIUpdates() async throws {
        let document = MessageEditorDocument()
        let (controller, window) = try await host(document)
        defer { window.isHidden = true }
        let view = try XCTUnwrap(findEditor(controller.view))
        let input = "Hello hello, verified reply edit. let answer = 42 😀"
        for code in [false, true] {
            document.load("")
            if code { document.toggleBlock(.codeBlock) }
            await updateLayout(controller)
            // Code blocks retain their terminating paragraph; typing occurs before it.
            let terminator = code ? "\n" : ""
            XCTAssertEqual(document.content.string, terminator)
            var expected = ""
            for character in input {
                let next = String(character)
                view.insertText(next)
                expected += next
                await updateLayout(controller)
                XCTAssertEqual(view.text, expected + terminator, "Native typing must not lose or reorder characters during redraw")
                XCTAssertEqual(document.content.string, expected + terminator)
                XCTAssertEqual(view.selectedRange, NSRange(location: (expected as NSString).length, length: 0))
            }
            let reopened = MessageEditorDocument()
            reopened.load(document.markdown)
            XCTAssertEqual(reopened.content.string, input + terminator)
            XCTAssertFalse(reopened.hasUnsupportedContent)
        }
    }

    func testHardwareUndoAndRedoCommandsRestoreToolbarEdits() async throws {
        let document = MessageEditorDocument()
        document.load("Hello")
        let (controller, window) = try await host(document)
        defer { window.isHidden = true }
        let view = try XCTUnwrap(findEditor(controller.view))
        let manager = try XCTUnwrap(view.undoManager)
        let undo = try XCTUnwrap(view.keyCommands?.first { $0.input == "z" && $0.modifierFlags == .command })
        let redo = try XCTUnwrap(view.keyCommands?.first { $0.input == "z" && $0.modifierFlags == [.command, .shift] })
        let undoAction = try XCTUnwrap(undo.action)
        XCTAssertEqual(NSStringFromSelector(undoAction), "undoComposer:")
        let redoAction = try XCTUnwrap(redo.action)
        manager.removeAllActions()
        manager.beginUndoGrouping()
        document.selection = NSRange(location: 0, length: 5)
        document.toggle(.bold)
        manager.endUndoGrouping()
        XCTAssertIdentical(view.undoManager, manager)
        XCTAssertTrue(view.canPerformAction(undoAction, withSender: undo))
        XCTAssertTrue(view.responds(to: undoAction))
        view.perform(undoAction, with: undo)
        XCTAssertEqual(document.markdown, "Hello")
        XCTAssertEqual(document.typingStyle, [])
        XCTAssertEqual(MessageEditorDocument.style(view.typingAttributes), [])
        XCTAssertTrue(view.canPerformAction(redoAction, withSender: redo))
        XCTAssertTrue(view.responds(to: redoAction))
        view.perform(redoAction, with: redo)
        XCTAssertEqual(document.markdown, "**Hello**")
        XCTAssertEqual(document.typingStyle, .bold)
        XCTAssertEqual(MessageEditorDocument.style(view.typingAttributes), .bold)
    }

    func testAttachmentRenameCanBeUndoneAndRedoneInTheNativeEditor() async throws {
        for source in ["[original.pdf](/api/files/file.pdf)", "![original](/api/files/image.png)"] {
            let document = MessageEditorDocument()
            document.load(source)
            let (controller, window) = try await host(document)
            defer { window.isHidden = true }
            let view = try XCTUnwrap(findEditor(controller.view))
            let undo = try XCTUnwrap(view.undoManager)
            undo.removeAllActions()
            undo.beginUndoGrouping()
            let attachment = try XCTUnwrap(document.attachments.first)
            XCTAssertTrue(document.renameAttachment(attachment, to: "Renamed [final]"))
            undo.endUndoGrouping()
            let renamed = document.markdown
            XCTAssertNotEqual(renamed, source)
            XCTAssertEqual(document.attachments.first?.name, "Renamed [final]")
            undo.undo()
            XCTAssertEqual(document.markdown, source)
            XCTAssertEqual(view.attributedText, document.content)
            undo.redo()
            XCTAssertEqual(document.markdown, renamed)
            XCTAssertEqual(view.attributedText, document.content)
        }
    }

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
        let parent = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false))
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

    func testRepeatedNativeReturnsContinueListsAcrossRedrawsAndExitEmptyItem() async throws {
        for style in [MessageEditorBlockStyle.bulletList, .numberedList] {
            let document = MessageEditorDocument()
            let (host, window) = try await host(document)
            defer { window.isHidden = true }
            let view = try XCTUnwrap(findEditor(host.view))
            document.toggleBlock(style)
            let coordinator = try XCTUnwrap(view.delegate as? MessageRichTextEditor.Coordinator)
            var expected: [String] = []
            for number in 1...12 {
                for character in "Item \(number) 😀" {
                    view.insertText(String(character))
                    await updateLayout(host)
                }
                expected.append(style == .bulletList ? "- Item \(number) 😀" : "\(number). Item \(number) 😀")
                XCTAssertEqual(document.markdown, expected.joined(separator: "\n"))
                let consumed = !coordinator.textView(view, shouldChangeTextIn: view.selectedRange, replacementText: "\n")
                XCTAssertTrue(consumed, "Return must continue item \(number)")
                if !consumed { view.insertText("\n") }
                await updateLayout(host)
                XCTAssertEqual(document.activeBlockStyle, style)
            }
            XCTAssertFalse(coordinator.textView(view, shouldChangeTextIn: view.selectedRange, replacementText: "\n"))
            XCTAssertNil(document.activeBlockStyle)
            XCTAssertEqual(document.markdown, expected.joined(separator: "\n") + "\n\n")
        }
    }

    func testKeyboardInsertionContinuesEveryListItem() async throws {
        for style in [MessageEditorBlockStyle.bulletList, .numberedList] {
            let document = MessageEditorDocument()
            let (host, window) = try await host(document)
            defer { window.isHidden = true }
            let view = try XCTUnwrap(findEditor(host.view))
            document.toggleBlock(style)
            for item in ["First", "Second", "Third"] {
                view.insertText(item)
                view.insertText("\n")
                await updateLayout(host)
            }
            let expected = style == .bulletList ? "- First\n- Second\n- Third\n- " : "1. First\n2. Second\n3. Third\n4. "
            XCTAssertEqual(document.markdown, expected)
            view.insertText("\n")
            XCTAssertNil(document.activeBlockStyle)
            XCTAssertEqual(document.markdown, String(expected.dropLast(style == .bulletList ? 2 : 3)) + "\n")
        }
    }

    func testQuotesDisplayWithoutMarkdownMarkersAndRetainTheirWireFormat() async throws {
        let document = MessageEditorDocument()
        document.load("> A **quoted** line\n> Second line\n\nPlain")
        let (host, window) = try await host(document)
        defer { window.isHidden = true }
        let view = try XCTUnwrap(findEditor(host.view))
        XCTAssertFalse(view.text.contains(">"))
        let range = (view.text as NSString).range(of: "quoted")
        let paragraph = try XCTUnwrap(view.attributedText.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle)
        XCTAssertGreaterThan(paragraph.headIndent, 0)
        XCTAssertTrue(MessageEditorDocument.style(view.attributedText.attributes(at: range.location, effectiveRange: nil)).contains(.bold))
        XCTAssertEqual(document.markdown, "> A **quoted** line\n> Second line\n\nPlain")
        XCTAssertEqual(document.plainText(in: NSRange(location: 0, length: document.content.length)), "A quoted line\nSecond line\n\nPlain")
    }

    func testNativeTypingBeforeTheQuotePrefixKeepsQuoteSemantics() async throws {
        let document = MessageEditorDocument()
        document.load("> hello")
        let (host, window) = try await host(document)
        defer { window.isHidden = true }
        let view = try XCTUnwrap(findEditor(host.view))
        view.selectedRange = NSRange(location: 0, length: 0)
        view.insertText("X")
        XCTAssertEqual(document.markdown, "> Xhello")
        XCTAssertEqual(document.activeBlockStyle, .quote)
        view.selectedRange = NSRange(location: 0, length: view.attributedText.length)
        view.insertText("Replacement")
        XCTAssertEqual(document.markdown, "> Replacement")
        let reopened = MessageEditorDocument()
        reopened.load(document.markdown)
        XCTAssertEqual(reopened.content.string, document.content.string)
    }

    func testCompletionsKeepLongDraftWithinSmallHeightBudget() {
        let document = MessageEditorDocument()
        document.load(String(repeating: "line\n", count: 20) + "@a")
        let host = UIHostingController(rootView: MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false),
                                                                       showsCompletions: true))
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
        MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false))
            .onAppear(perform: appeared)
    }
}
