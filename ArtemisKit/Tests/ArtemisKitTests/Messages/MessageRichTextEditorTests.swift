import SwiftUI
import UIKit
import XCTest
@testable import Messages

@MainActor
final class MessageRichTextEditorTests: XCTestCase {
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
        let parent = MessageRichTextEditor(document: MessageEditorDocument(), placeholder: "Message", isFocused: binding, expanded: false)
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
        let parent = MessageRichTextEditor(document: MessageEditorDocument(), placeholder: "Message", isFocused: binding, expanded: false)
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
        let parent = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false), expanded: false)
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
            let parent = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false), expanded: false)
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
            let parent = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false), expanded: false)
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
        let parent = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false), expanded: false)
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

    func testExpandingAnEmptyEditorActuallyCreatesMoreWritingSpace() {
        let document = MessageEditorDocument()
        let compact = fittedHeight(document: document, expanded: false)
        let expanded = fittedHeight(document: document, expanded: true)
        XCTAssertGreaterThanOrEqual(expanded - compact, 100)
        XCTAssertLessThanOrEqual(expanded, 320)
    }

    func testExpandedEditorRequestsSpaceDuringParentMinimumHeightMeasurement() {
        let editor = MessageRichTextEditor(document: MessageEditorDocument(), placeholder: "Message", isFocused: .constant(false), expanded: true)
        let host = UIHostingController(rootView: editor)
        // VStack asks for a minimum with zero proposed height before allocating its children.
        XCTAssertGreaterThanOrEqual(host.sizeThatFits(in: CGSize(width: 320, height: 0)).height, 200)
    }

    func testNativeHostingPreservesRestoredDraftAndReferencePayload() {
        let document = MessageEditorDocument()
        let draft = "**Draft** for [user]Alice(alice)[/user]"
        document.load(draft)
        _ = fittedHeight(document: document, expanded: false)
        XCTAssertEqual(document.markdown, draft)
        XCTAssertTrue(document.content.string.contains("Draft"))
        XCTAssertFalse(document.hasUnsupportedContent)
    }

    private func fittedHeight(document: MessageEditorDocument, expanded: Bool) -> CGFloat {
        let editor = MessageRichTextEditor(document: document, placeholder: "Message", isFocused: .constant(false), expanded: expanded)
        let host = UIHostingController(rootView: editor)
        return host.sizeThatFits(in: CGSize(width: 320, height: 600)).height
    }
}
