import XCTest
@testable import Messages

@MainActor
final class MessageEditorBlockDocumentTests: XCTestCase {
    func testQuoteToolbarPreservesFormattingAndUnicodeWhenToggledOff() {
        let editor = MessageEditorDocument()
        editor.load("😀 **one**\ntwo")
        editor.selection = NSRange(location: 0, length: editor.content.length)
        editor.toggleBlock(.quote)
        XCTAssertEqual(editor.markdown, "> 😀 **one**\n> two")
        XCTAssertEqual(editor.activeBlockStyle, .quote)
        editor.toggleBlock(.quote)
        XCTAssertEqual(editor.markdown, "😀 **one**\ntwo")
        XCTAssertNil(editor.activeBlockStyle)
    }

    func testTypedQuoteContinuesAndExitsOnEmptyLineOrBackspace() {
        let editor = MessageEditorDocument()
        editor.insertText(">")
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: " "))
        XCTAssertEqual(editor.activeBlockStyle, .quote)
        editor.insertText("Quoted")
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        XCTAssertEqual(editor.markdown, "> Quoted\n> ")
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        XCTAssertEqual(editor.markdown, "> Quoted\n\n")
        XCTAssertNil(editor.activeBlockStyle)
        editor.toggleBlock(.quote)
        let caret = editor.selection.location
        XCTAssertTrue(editor.handleReplacement(in: NSRange(location: caret - 1, length: 1), text: ""))
        XCTAssertNil(editor.activeBlockStyle)
    }

    func testBulletToolbarPreservesInlineFormattingAndUnicodeSelection() {
        let editor = MessageEditorDocument()
        editor.load("😀 **one**\ntwo")
        editor.selection = NSRange(location: 3, length: 7)
        editor.toggleBlock(.bulletList)
        XCTAssertEqual(editor.content.string, "• 😀 one\n• two")
        XCTAssertEqual(editor.markdown, "- 😀 **one**\n- two")
        XCTAssertEqual(editor.plainText(in: editor.selection), "one\n• two")
        editor.toggleBlock(.bulletList)
        XCTAssertEqual(editor.markdown, "😀 **one**\ntwo")
    }

    func testTypedBulletMarkerContinuesOnReturnAndExitsEmptyItem() {
        let editor = MessageEditorDocument()
        editor.accept(NSAttributedString(string: "-", attributes: MessageEditorDocument.attributes([])), selection: NSRange(location: 1, length: 0))
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: " "))
        XCTAssertEqual(editor.content.string, "• ")
        editor.insertText("first")
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        XCTAssertEqual(editor.content.string, "• first\n• ")
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        XCTAssertEqual(editor.content.string, "• first\n\n")
        XCTAssertEqual(editor.markdown, "- first\n\n")
        XCTAssertNil(editor.activeBlockStyle)
    }

    func testCreatingEmptyListAfterProseAddsTheRequiredBlankParagraph() {
        for style: MessageEditorBlockStyle in [.bulletList, .numberedList] {
            let editor = MessageEditorDocument()
            editor.load("before\n")
            editor.toggleBlock(style)
            let marker = style == .bulletList ? "• " : "1. "
            let source = style == .bulletList ? "- " : "1. "
            XCTAssertEqual(editor.content.string, "before\n\n" + marker)
            XCTAssertEqual(editor.markdown, "before\n\n" + source)
            let reopened = MessageEditorDocument()
            reopened.load(editor.markdown)
            XCTAssertFalse(reopened.hasUnsupportedContent)
            XCTAssertEqual(reopened.content.string, editor.content.string)
        }
    }

    func testTypingEmptyListAfterProseAddsTheRequiredBlankParagraph() {
        let editor = MessageEditorDocument()
        editor.accept(NSAttributedString(string: "before\n-", attributes: MessageEditorDocument.attributes([])), selection: NSRange(location: 8, length: 0))
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: " "))
        XCTAssertEqual(editor.content.string, "before\n\n• ")
        XCTAssertEqual(editor.selection, NSRange(location: 10, length: 0))
        XCTAssertEqual(editor.markdown, "before\n\n- ")
    }

    func testNumberedReturnIncrementsAndBackspaceRemovesMarker() {
        let editor = MessageEditorDocument()
        editor.load("7. seven")
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        editor.insertText("eight")
        XCTAssertEqual(editor.markdown, "7. seven\n8. eight")
        editor.selection = NSRange(location: 12, length: 0)
        XCTAssertTrue(editor.handleReplacement(in: NSRange(location: 11, length: 1), text: ""))
        XCTAssertEqual(editor.markdown, "7. seven\n\neight")
    }

    func testCodeBlockToolbarUsesLiteralContentsAndCanBeRemoved() {
        let editor = MessageEditorDocument()
        editor.load("let x = 1\nprint(x)")
        editor.selection = NSRange(location: 0, length: editor.content.length)
        editor.toggleBlock(.codeBlock)
        XCTAssertEqual(editor.markdown, "```\nlet x = 1\nprint(x)\n```")
        XCTAssertEqual(editor.activeBlockStyle, .codeBlock)
        XCTAssertNil(editor.completion)
        XCTAssertFalse(editor.canSetLink)
        editor.toggleBlock(.codeBlock)
        XCTAssertEqual(editor.markdown, "let x = 1\nprint(x)\n")
    }

    func testCodeReturnDoesNotContinueListsOrInterpretMarkdown() {
        let editor = MessageEditorDocument()
        editor.load("```swift\n- literal $x$\n```")
        editor.selection = NSRange(location: 13, length: 0)
        XCTAssertFalse(editor.handleReplacement(in: editor.selection, text: "\n"))
        editor.insertText("\n[user]Alice(alice)[/user]")
        XCTAssertTrue(editor.markdown.contains("[user]Alice(alice)[/user]"))
        XCTAssertFalse(editor.hasUnsupportedContent)
        XCTAssertNil(editor.completion)
        let reopened = MessageEditorDocument()
        reopened.load(editor.markdown)
        XCTAssertEqual(reopened.content.string, editor.content.string)
    }

    func testMiddleParagraphListConversionReopensWithTheSameParagraphs() {
        let editor = MessageEditorDocument()
        editor.load("before\nitem\nafter")
        editor.selection = NSRange(location: 7, length: 4)
        editor.toggleBlock(.bulletList)
        XCTAssertEqual(editor.content.string, "before\n• item\n\nafter")
        XCTAssertEqual(editor.markdown, "before\n- item\n\nafter")
        let reopened = MessageEditorDocument()
        reopened.load(editor.markdown)
        XCTAssertEqual(reopened.content.string, editor.content.string)
    }

    func testRemovingMiddleListItemSeparatesTheResultingParagraph() {
        let editor = MessageEditorDocument()
        editor.load("- before\n- item\n- after")
        editor.selection = NSRange(location: 11, length: 4)
        editor.toggleBlock(.bulletList)
        XCTAssertEqual(editor.content.string, "• before\n\nitem\n• after")
        let reopened = MessageEditorDocument()
        reopened.load(editor.markdown)
        XCTAssertEqual(reopened.content.string, editor.content.string)
    }

    func testReturnAtEmptyFinalCodeParagraphExitsToOrdinaryProse() {
        let editor = MessageEditorDocument()
        editor.load("```swift\ncode\n```")
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        XCTAssertEqual(editor.markdown, "```swift\ncode\n```\n\n")
        XCTAssertNil(editor.activeBlockStyle)
        editor.insertText("After")
        XCTAssertEqual(editor.markdown, "```swift\ncode\n```\n\nAfter")
        let reopened = MessageEditorDocument()
        reopened.load(editor.markdown)
        XCTAssertEqual(reopened.content.string, editor.content.string)
    }

    func testReturnInsideCodeRemainsLiteralUntilTheFinalEmptyParagraph() {
        let editor = MessageEditorDocument()
        editor.load("```\nfirst\n\n```\nAfter")
        editor.selection = NSRange(location: 5, length: 0)
        XCTAssertFalse(editor.handleReplacement(in: editor.selection, text: "\n"))
        editor.selection = NSRange(location: 6, length: 0)
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        XCTAssertEqual(editor.markdown, "```\nfirst\n```\n\nAfter")
        XCTAssertNil(editor.activeBlockStyle)
    }

    func testReturnExitsEmptyCodeWithoutDiscardingItsFence() {
        let editor = MessageEditorDocument()
        editor.load("```\n```")
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        editor.insertText("After")
        XCTAssertEqual(editor.markdown, "```\n```\n\nAfter")
    }

    func testWhitespaceOnlyListItemExitsOnReturn() {
        let editor = MessageEditorDocument()
        editor.load("- first\n-    ")
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        XCTAssertEqual(editor.content.string, "• first\n\n")
        XCTAssertEqual(editor.markdown, "- first\n\n")
        XCTAssertNil(editor.activeBlockStyle)
    }

    func testTypedMarkersBeforeExistingNewlinePreserveFollowingParagraphAndCaret() {
        for (marker, display, source) in [("-", "• ", "- "), ("4.", "4. ", "4. ")] {
            let editor = MessageEditorDocument()
            editor.accept(NSAttributedString(string: marker + "\nAfter", attributes: MessageEditorDocument.attributes([])),
                          selection: NSRange(location: marker.utf16.count, length: 0))
            XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: " "))
            XCTAssertEqual(editor.content.string, display + "\n\nAfter")
            XCTAssertEqual(editor.selection, NSRange(location: display.utf16.count, length: 0))
            XCTAssertEqual(editor.markdown, source + "\n\nAfter")
        }
    }

    func testEmptyFencedCodeTypingStartsInsideEmptyParagraph() {
        let editor = MessageEditorDocument()
        editor.load("```\n```")
        XCTAssertEqual(editor.selection, NSRange(location: 0, length: 0))
        editor.insertText("value")
        XCTAssertEqual(editor.markdown, "```\nvalue\n```")
    }

    func testPastedAdjacentCodeBlocksKeepTheirSeparateFences() {
        let editor = MessageEditorDocument()
        editor.load("```\nfirst\n```\nafter")
        editor.selection = NSRange(location: 6, length: 0)
        editor.insertMarkup("```\nsecond\n```")
        XCTAssertEqual(editor.markdown, "```\nfirst\n```\n```\nsecond\n```\nafter")
    }

    func testRemovingFencedCodeClearsPendingInlineCodeTyping() {
        let editor = MessageEditorDocument()
        editor.load("```\nfirst\n```")
        editor.selection = NSRange(location: 2, length: 0)
        editor.typingStyle = .code
        editor.toggleBlock(.codeBlock)
        editor.insertText("next")
        XCTAssertEqual(editor.markdown, "finextrst\n")
    }

    func testTypingAfterEmptyListExitReopensAsAStandaloneParagraph() {
        let editor = MessageEditorDocument()
        editor.load("- first\n- ")
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        editor.insertText("After")
        XCTAssertEqual(editor.markdown, "- first\n\nAfter")
        let reopened = MessageEditorDocument()
        reopened.load(editor.markdown)
        XCTAssertFalse(reopened.hasUnsupportedContent)
        XCTAssertEqual(reopened.content.string, editor.content.string)
    }

    func testListReferenceInsertionPreservesContinuationAndAtomicDeletion() {
        let editor = MessageEditorDocument()
        editor.load("- ")
        editor.insertMarkup("[user]Alice(alice)[/user]")
        XCTAssertEqual(editor.activeBlockStyle, .bulletList)
        XCTAssertEqual(editor.atomicSelectionForDeletion(NSRange(location: 2, length: 1)), NSRange(location: 2, length: 1))
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        XCTAssertEqual(editor.markdown, "- [user]Alice(alice)[/user]\n- ")
    }

    func testSettingListLinkPreservesContinuation() {
        let editor = MessageEditorDocument()
        editor.load("- item")
        editor.selection = NSRange(location: 2, length: 4)
        editor.setLink(label: "site", address: "https://example.org")
        editor.selection = NSRange(location: editor.content.length, length: 0)
        XCTAssertEqual(editor.activeBlockStyle, .bulletList)
        XCTAssertTrue(editor.handleReplacement(in: editor.selection, text: "\n"))
        XCTAssertEqual(editor.markdown, "- [site](https://example.org)\n- ")
    }

    func testCodeBlockAtCaretTogglesWholeBlockAndRejectsMixedInlineEdits() {
        let editor = MessageEditorDocument()
        editor.load("```swift\none\ntwo\n```\nplain")
        editor.selection = NSRange(location: 0, length: editor.content.length)
        editor.toggle(.bold)
        editor.setLink(label: "changed", address: "https://example.org")
        XCTAssertEqual(editor.markdown, "```swift\none\ntwo\n```\nplain")
        editor.selection = NSRange(location: 1, length: 0)
        editor.toggleBlock(.codeBlock)
        XCTAssertEqual(editor.markdown, "one\ntwo\nplain")
    }

    func testMarkdownPastedInsideCodeRemainsLiteral() {
        let editor = MessageEditorDocument()
        editor.load("```\ncode\n```")
        editor.selection = NSRange(location: 4, length: 0)
        editor.insertMarkup("**bold** [user]Alice(alice)[/user]")
        XCTAssertEqual(editor.content.string, "code**bold** [user]Alice(alice)[/user]\n")
        XCTAssertEqual(editor.markdown, "```\ncode**bold** [user]Alice(alice)[/user]\n```")
    }

    func testPastedBlocksEstablishParagraphBoundaries() {
        for (source, display, markdown) in [
            ("- item", "before\n• item\n\nafter", "before\n- item\n\nafter"),
            ("```\ncode\n```", "before\ncode\nafter", "before\n```\ncode\n```\nafter")
        ] {
            let editor = MessageEditorDocument()
            editor.load("beforeafter")
            editor.selection = NSRange(location: 6, length: 0)
            editor.insertMarkup(source)
            XCTAssertEqual(editor.content.string, display)
            XCTAssertEqual(editor.markdown, markdown)
            XCTAssertNotNil(MessageEditorCodec.decode(editor.markdown))
        }
    }
}
