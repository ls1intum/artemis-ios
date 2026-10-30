import SwiftUI
import UIKit
import XCTest
@testable import Messages

@MainActor
final class MessageRichTextEditorTests: XCTestCase {
    func testNativeAttributeNormalizationInLaterListItemsKeepsContinuation() {
        for style in [MessageEditorBlockStyle.bulletList, .numberedList] {
            let document = MessageEditorDocument()
            document.toggleBlock(style)
            document.insertText("First")
            XCTAssertTrue(document.handleReplacement(in: document.selection, text: "\n"))
            let native = NSMutableAttributedString(attributedString: document.content)
            // Native replacement/autocorrection may supply standard attributes for the item body.
            native.append(NSAttributedString(string: "Second", attributes: MessageEditorDocument.attributes([])))
            document.accept(native, selection: NSRange(location: native.length, length: 0))
            XCTAssertEqual(document.activeBlockStyle, style)
            XCTAssertTrue(document.handleReplacement(in: document.selection, text: "\n"))
            document.insertText("Third")
            XCTAssertEqual(document.markdown, style == .bulletList ? "- First\n- Second\n- Third" : "1. First\n2. Second\n3. Third")
        }
    }

    func testCodeBlockBackgroundExtendsBeyondShortTextAndStopsBeforePlainText() throws {
        let document = MessageEditorDocument()
        document.load("```\nx\na longer line\n```\n\nPlain text")
        let view = MessageComposerTextView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
        view.backgroundColor = .systemBackground
        view.document = document
        view.attributedText = document.content
        view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { context in
            view.layer.render(in: context.cgContext)
        }
        let cgImage = try XCTUnwrap(image.cgImage)
        let data = try XCTUnwrap(cgImage.dataProvider?.data)
        let bytes = try XCTUnwrap(CFDataGetBytePtr(data))
        func pixel(_ x: Int, _ y: Int) -> [UInt8] {
            let start = y * cgImage.bytesPerRow + x * (cgImage.bitsPerPixel / 8)
            return Array(UnsafeBufferPointer(start: bytes + start, count: 3))
        }
        XCTAssertNotEqual(pixel(280, 15), pixel(280, 150), "Even the short first code line needs a full-width background")
        XCTAssertEqual(pixel(280, 15), pixel(280, 35), "Code lines must have a consistent background width")
        XCTAssertEqual(pixel(280, 80), pixel(280, 150), "Code styling must not extend into the following paragraph")
    }

    func testProgrammaticFocusReconciliationDoesNotWriteSwiftUIState() {
        var focus = true
        var writes = 0
        let binding = Binding(get: { focus }, set: { focus = $0; writes += 1 })
        let parent = MessageRichTextEditor(document: MessageEditorDocument(), placeholder: "Message", isFocused: binding)
        let coordinator = parent.makeCoordinator()
        let view = MessageComposerTextView()
        coordinator.applying = true
        coordinator.textViewDidEndEditing(view)
        coordinator.textViewDidBeginEditing(view)
        XCTAssertEqual(writes, 0, "UIKit callbacks during updateUIView must not mutate a SwiftUI binding")
        XCTAssertTrue(focus)
    }

    func testUserFocusChangesArePublishedOnce() {
        var focus = false
        var writes = 0
        let binding = Binding(get: { focus }, set: { focus = $0; writes += 1 })
        let parent = MessageRichTextEditor(document: MessageEditorDocument(), placeholder: "Message", isFocused: binding)
        let coordinator = parent.makeCoordinator()
        let view = MessageComposerTextView()
        coordinator.textViewDidBeginEditing(view)
        coordinator.textViewDidBeginEditing(view)
        XCTAssertTrue(focus)
        XCTAssertEqual(writes, 1)
        coordinator.textViewDidEndEditing(view)
        coordinator.textViewDidEndEditing(view)
        XCTAssertFalse(focus)
        XCTAssertEqual(writes, 2)
    }

    func testDuplicateCaretNotificationKeepsPendingInlineCodeForNativeTyping() {
        let document = MessageEditorDocument()
        document.load("Before ")
        let parent = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false))
        let coordinator = parent.makeCoordinator()
        let view = MessageComposerTextView()
        view.attributedText = document.content
        view.selectedRange = document.selection
        view.typingAttributes = MessageEditorDocument.attributes([])
        document.toggle(.code)
        coordinator.textViewDidChangeSelection(view)
        XCTAssertTrue(document.typingStyle.contains(.code))
        view.typingAttributes = MessageEditorDocument.attributes(document.typingStyle)
        view.insertText("value")
        coordinator.textViewDidChange(view)
        XCTAssertEqual(document.markdown, "Before `value`")
    }

    func testSelectionBeforeTextChangeKeepsBlockAttributesDuringCharacterTyping() {
        for style in [MessageEditorBlockStyle.bulletList, .numberedList, .codeBlock] {
            let document = MessageEditorDocument()
            document.toggleBlock(style)
            let parent = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false))
            let coordinator = parent.makeCoordinator()
            let view = MessageComposerTextView()
            view.attributedText = document.content
            view.selectedRange = document.selection
            view.typingAttributes = document.typingAttributes
            for character in "First" {
                let range = view.selectedRange
                view.textStorage.replaceCharacters(in: range, with: NSAttributedString(string: String(character), attributes: view.typingAttributes))
                view.selectedRange = NSRange(location: range.location + 1, length: 0)
                // UIKit may notify the caret before textViewDidChange. Read against the new text.
                coordinator.textViewDidChangeSelection(view)
                coordinator.textViewDidChange(view)
                XCTAssertEqual(document.activeBlockStyle, style)
                XCTAssertEqual(MessageEditorDocument.block(view.typingAttributes)?.style, style)
            }
            if style != .codeBlock {
                XCTAssertFalse(coordinator.textView(view, shouldChangeTextIn: view.selectedRange, replacementText: "\n"))
                XCTAssertTrue(document.content.string.hasSuffix(style == .bulletList ? "\n• " : "\n2. "))
            }
        }
    }

    func testNativeAttributeNormalizationDoesNotCancelExplicitInlineTypingStyle() {
        for style in [MessageEditorStyle.code, .bold, .italic, .underline, .strikethrough] {
            let document = MessageEditorDocument()
            document.load("Before ")
            document.toggle(style)
            let parent = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false))
            let coordinator = parent.makeCoordinator()
            let view = MessageComposerTextView()
            view.attributedText = document.content
            view.selectedRange = document.selection
            view.typingAttributes = document.typingAttributes
            for character in "value" {
                let range = view.selectedRange
                view.textStorage.replaceCharacters(in: range, with: NSAttributedString(string: String(character), attributes: view.typingAttributes))
                view.selectedRange = NSRange(location: range.location + 1, length: 0)
                // Native typing attributes may be normalized before the selection notification.
                view.typingAttributes = MessageEditorDocument.attributes([])
                coordinator.textViewDidChangeSelection(view)
                coordinator.textViewDidChange(view)
                XCTAssertEqual(document.typingStyle, style)
                XCTAssertEqual(MessageEditorDocument.style(view.typingAttributes), style)
            }
            let expected = MessageEditorCodec.encode([MessageEditorSpan(text: "Before "), MessageEditorSpan(text: "value", style: style)])
            XCTAssertEqual(document.markdown, expected)
        }
    }

    func testMovingFromCodeToTheStartOfAPlainParagraphRestoresPlainTyping() {
        let document = MessageEditorDocument()
        document.load("```\ncode\n```\nplain")
        document.selection = NSRange(location: 2, length: 0)
        document.typingStyle = .code
        let parent = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false))
        let coordinator = parent.makeCoordinator()
        let view = MessageComposerTextView()
        view.attributedText = document.content
        view.selectedRange = document.selection
        view.typingAttributes = document.typingAttributes
        view.updateTypingTraits(for: document)
        XCTAssertEqual(view.autocorrectionType, .no)
        view.selectedRange = NSRange(location: 5, length: 0)
        coordinator.textViewDidChangeSelection(view)
        view.updateTypingTraits(for: document)
        XCTAssertNil(document.activeBlockStyle)
        XCTAssertEqual(document.typingStyle, [])
        XCTAssertEqual(view.autocorrectionType, .default)
        view.insertText("new ")
        coordinator.textViewDidChange(view)
        XCTAssertEqual(document.markdown, "```\ncode\n```\nnew plain")
    }

    func testEditorGrowsWithContentAndCapsLongDrafts() {
        let document = MessageEditorDocument()
        let empty = fittedHeight(document: document)
        document.load("First\nSecond\nThird")
        XCTAssertGreaterThan(fittedHeight(document: document), empty)
        document.load(String(repeating: "A long draft line\n", count: 40))
        XCTAssertLessThanOrEqual(fittedHeight(document: document), 160)
    }

    func testEditorRespectsSmallHeightBudgetAndMinimumMeasurement() {
        let document = MessageEditorDocument()
        document.load(String(repeating: "line\n", count: 40))
        let editor = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false))
        let host = UIHostingController(rootView: editor)
        XCTAssertLessThanOrEqual(host.sizeThatFits(in: CGSize(width: 320, height: 65)).height, 65)
        XCTAssertEqual(host.sizeThatFits(in: CGSize(width: 320, height: 0)).height, 44,
                       "VStack's minimum-height probe must allow a long draft to shrink above the keyboard")
    }

    func testNativeHostingPreservesRestoredDraftAndReferencePayload() {
        let document = MessageEditorDocument()
        let draft = "**Draft** for [user]Alice(alice)[/user]"
        document.load(draft)
        _ = fittedHeight(document: document)
        XCTAssertEqual(document.markdown, draft)
        XCTAssertTrue(document.content.string.contains("Draft"))
        XCTAssertFalse(document.hasUnsupportedContent)
    }

    func testReplacingDocumentClearsUndoEvenWhenItsAttributedContentIsUnchanged() async throws {
        for replacement in ["**First**", "Second"] {
            let first = MessageEditorDocument()
            first.load("First")
            let previousKeyWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows).first(where: \.isKeyWindow)
            let (host, window) = try await hostRebindingEditor(first)
            defer {
                window.isHidden = true
                window.rootViewController = nil
                previousKeyWindow?.makeKeyAndVisible()
            }
            let original = try XCTUnwrap(findEditor(in: host.view))
            let undo = try XCTUnwrap(original.undoManager)
            undo.removeAllActions()
            undo.beginUndoGrouping()
            first.selection = NSRange(location: 0, length: first.content.length)
            first.toggle(.bold)
            undo.endUndoGrouping()
            XCTAssertEqual(first.markdown, "**First**")
            XCTAssertTrue(undo.canUndo, "The old document must have a real native undo operation")

            let second = MessageEditorDocument()
            second.load(replacement)
            if replacement == first.markdown {
                XCTAssertEqual(original.attributedText, second.content, "Exercise the path that skips assigning attributedText")
            }
            host.rootView = RebindingEditorHarness(document: second)
            await updateRebindingEditor(host)
            let reused = try XCTUnwrap(findEditor(in: host.view))
            XCTAssertIdentical(reused, original)
            XCTAssertIdentical(reused.document, second)
            XCTAssertNil(first.applyEdit)
            XCTAssertNil(first.applyTypingAttributes)

            let replacementUndo = try XCTUnwrap(reused.undoManager)
            XCTAssertFalse(replacementUndo.canUndo, "Undo belongs to a document, even when the native view is reused")
            replacementUndo.undo()
            XCTAssertEqual(second.markdown, replacement, "Undo must not import the previous document's content")
            XCTAssertEqual(first.markdown, "**First**")
            XCTAssertEqual(reused.attributedText, second.content)
        }
    }

    func testUpdatingTheSameDocumentPreservesNativeUndo() async throws {
        let document = MessageEditorDocument()
        document.load("First")
        let previousKeyWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow)
        let (host, window) = try await hostRebindingEditor(document)
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousKeyWindow?.makeKeyAndVisible()
        }
        let editor = try XCTUnwrap(findEditor(in: host.view))
        let undo = try XCTUnwrap(editor.undoManager)
        undo.removeAllActions()
        undo.beginUndoGrouping()
        document.selection = NSRange(location: 0, length: document.content.length)
        document.toggle(.bold)
        undo.endUndoGrouping()
        host.rootView = RebindingEditorHarness(document: document)
        await updateRebindingEditor(host)

        XCTAssertTrue(undo.canUndo)
        undo.undo()
        XCTAssertEqual(document.markdown, "First")
        XCTAssertEqual(editor.attributedText, document.content)
    }

    func testReplacingDocumentDuringCompositionDoesNotCommitOldMarkedTextIntoReplacement() async throws {
        let first = MessageEditorDocument()
        first.load("First ")
        let previousKeyWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow)
        let (host, window) = try await hostRebindingEditor(first, isFocused: true)
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousKeyWindow?.makeKeyAndVisible()
        }
        let original = try XCTUnwrap(findEditor(in: host.view))
        XCTAssertTrue(original.becomeFirstResponder())
        original.selectedRange = NSRange(location: first.content.length, length: 0)
        original.setMarkedText("pending", selectedRange: NSRange(location: 7, length: 0))
        XCTAssertNotNil(original.markedTextRange, "Exercise a real native composition before reusing the editor")
        XCTAssertEqual(original.text, "First pending")

        let second = MessageEditorDocument()
        second.load("Second")
        host.rootView = RebindingEditorHarness(document: second, isFocused: true)
        await updateRebindingEditor(host)
        let reused = try XCTUnwrap(findEditor(in: host.view))
        XCTAssertIdentical(reused, original)
        XCTAssertIdentical(reused.document, second)
        reused.unmarkText()
        // UIKit can deliver the final edit callback after SwiftUI has replaced the document.
        let coordinator = try XCTUnwrap(reused.delegate as? MessageRichTextEditor.Coordinator)
        coordinator.textViewDidChange(reused)

        XCTAssertEqual(second.markdown, "Second", "Finishing the old composition must not overwrite the replacement document")
        XCTAssertEqual(reused.text, "Second")
    }

    func testUpdatingSameDocumentPreservesMarkedTextUntilCompositionEnds() async throws {
        let document = MessageEditorDocument()
        document.load("First ")
        let previousKeyWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow)
        let (host, window) = try await hostRebindingEditor(document, isFocused: true)
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousKeyWindow?.makeKeyAndVisible()
        }
        let editor = try XCTUnwrap(findEditor(in: host.view))
        XCTAssertTrue(editor.becomeFirstResponder())
        editor.selectedRange = NSRange(location: document.content.length, length: 0)
        editor.setMarkedText("pending", selectedRange: NSRange(location: 7, length: 0))
        XCTAssertNotNil(editor.markedTextRange)

        host.rootView = RebindingEditorHarness(document: document, isFocused: true)
        await updateRebindingEditor(host)
        XCTAssertIdentical(findEditor(in: host.view), editor)
        XCTAssertNotNil(editor.markedTextRange, "An ordinary update must let the input method finish its composition")
        XCTAssertEqual(editor.text, "First pending")
        editor.unmarkText()
        let coordinator = try XCTUnwrap(editor.delegate as? MessageRichTextEditor.Coordinator)
        coordinator.textViewDidChange(editor)
        XCTAssertEqual(document.markdown, "First pending")
    }

    private func hostRebindingEditor(_ document: MessageEditorDocument, isFocused: Bool = false) async throws
        -> (UIHostingController<RebindingEditorHarness>, UIWindow) {
        let window = try makeTestWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 600))
        let appeared = expectation(description: "Rebinding editor appeared")
        appeared.assertForOverFulfill = false
        let host = UIHostingController(rootView: RebindingEditorHarness(document: document, isFocused: isFocused,
                                                                        appeared: { appeared.fulfill() }))
        window.rootViewController = host
        window.makeKeyAndVisible()
        await fulfillment(of: [appeared], timeout: 2)
        host.view.layoutIfNeeded()
        return (host, window)
    }

    private func updateRebindingEditor(_ host: UIHostingController<RebindingEditorHarness>) async {
        let updated = expectation(description: "Rebinding editor updated")
        DispatchQueue.main.async {
            _ = host.sizeThatFits(in: CGSize(width: 390, height: 600))
            host.view.layoutIfNeeded()
            updated.fulfill()
        }
        await fulfillment(of: [updated], timeout: 2)
    }

    private func findEditor(in view: UIView) -> MessageComposerTextView? {
        if let editor = view as? MessageComposerTextView { return editor }
        return view.subviews.lazy.compactMap { self.findEditor(in: $0) }.first
    }

    private func fittedHeight(document: MessageEditorDocument) -> CGFloat {
        let editor = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false))
        let host = UIHostingController(rootView: editor)
        return host.sizeThatFits(in: CGSize(width: 320, height: 600)).height
    }
}

private struct RebindingEditorHarness: View {
    let document: MessageEditorDocument
    var isFocused = false
    var appeared: () -> Void = {}

    var body: some View {
        MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(isFocused))
            .onAppear(perform: appeared)
    }
}
