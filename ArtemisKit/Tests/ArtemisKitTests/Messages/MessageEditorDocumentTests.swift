import UIKit
import XCTest
@testable import Messages

@MainActor
final class MessageEditorDocumentTests: XCTestCase {
    func testEmojiInsertionBeforeQuotePrefixPreservesTheQuote() {
        let editor = MessageEditorDocument()
        editor.load("> Hello")
        editor.selection = NSRange(location: 0, length: 0)
        editor.insertText("😀")
        XCTAssertEqual(editor.markdown, "> 😀Hello")
        XCTAssertEqual(editor.activeBlockStyle, .quote)
        XCTAssertEqual(editor.selection, NSRange(location: 3, length: 0))
    }

    func testToolbarCompletionBeforeQuotePrefixPreservesTheQuote() {
        for (trigger, expected) in [(Character("@"), "> @Hello"), (Character("#"), "> #Hello")] {
            let editor = MessageEditorDocument()
            editor.load("> Hello")
            editor.selection = NSRange(location: 0, length: 0)
            editor.beginCompletion(trigger)
            XCTAssertEqual(editor.markdown, expected)
            XCTAssertEqual(editor.activeBlockStyle, .quote)
            XCTAssertEqual(editor.completion?.trigger, trigger)
            XCTAssertEqual(editor.completion?.range, NSRange(location: 1, length: 1))
        }
    }

    func testLinkInsertionBeforeQuotePrefixPreservesTheQuote() {
        let editor = MessageEditorDocument()
        editor.load("> Hello")
        editor.selection = NSRange(location: 0, length: 0)
        editor.setLink(label: "site", address: "https://example.org")
        XCTAssertEqual(editor.markdown, "> [site](https://example.org)Hello")
        XCTAssertEqual(editor.activeBlockStyle, .quote)
        XCTAssertEqual(editor.selection, NSRange(location: 1, length: 4))
    }

    func testLinkReplacementOfWholeQuotePreservesItsStructuralPrefix() {
        let editor = MessageEditorDocument()
        editor.load("> Hello")
        editor.selection = NSRange(location: 0, length: editor.content.length)
        editor.setLink(label: "site", address: "https://example.org")
        XCTAssertEqual(editor.markdown, "> [site](https://example.org)")
        XCTAssertEqual(editor.activeBlockStyle, .quote)
        XCTAssertEqual(editor.selection, NSRange(location: 1, length: 4))
    }

    func testCombiningTextAfterAtomicReferencesPreservesTheirWirePayloads() {
        for source in ["[user]Alice(alice)[/user]", "[report](/api/files/report.pdf)", "![image](/api/files/image.png)"] {
            for suffix in ["\u{0301}", "\u{FE0F}"] {
                let editor = MessageEditorDocument()
                editor.load(source)
                editor.insertText(suffix)
                XCTAssertEqual(editor.markdown, source + suffix)
                let reopened = MessageEditorDocument()
                reopened.load(editor.markdown)
                XCTAssertFalse(reopened.hasUnsupportedContent)
                XCTAssertEqual(reopened.content.string, editor.content.string)
                XCTAssertEqual(MessageEditorDocument.spans(reopened.content).compactMap(\.reference).map(\.markup), [source])
            }
        }
    }

    func testLinksCannotBeCreatedAcrossParagraphsOrWithMultilineLabels() {
        for source in ["first\nsecond", "- one\n- two", "> one\n> two"] {
            let editor = MessageEditorDocument()
            editor.load(source)
            editor.selection = NSRange(location: 0, length: editor.content.length)
            XCTAssertFalse(editor.canSetLink)
            editor.setLink(label: "link", address: "https://example.org")
            XCTAssertEqual(editor.markdown, source)
        }
        let editor = MessageEditorDocument()
        editor.setLink(label: "two\nlines", address: "https://example.org")
        XCTAssertEqual(editor.markdown, "")
    }

    func testExistingMultilineLinkCanBeConvertedToAListWithoutCorruptingItsMarkdown() {
        let editor = MessageEditorDocument()
        editor.load("[first\nsecond](https://example.org)")
        editor.selection = NSRange(location: 0, length: editor.content.length)
        editor.toggleBlock(.bulletList)
        XCTAssertEqual(editor.markdown, "- [first](https://example.org)\n- [second](https://example.org)")
        let reopened = MessageEditorDocument()
        reopened.load(editor.markdown)
        XCTAssertFalse(reopened.hasUnsupportedContent)
        XCTAssertEqual(reopened.content.string, editor.content.string)
    }

    func testInlineCodeHasDistinctForegroundAndDisablingItRestoresTextColor() {
        let document = MessageEditorDocument()
        document.toggle(.code)
        XCTAssertEqual(document.typingAttributes[.foregroundColor] as? UIColor, .systemRed)
        document.insertText("value")
        XCTAssertEqual(document.content.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor, .systemRed)
        document.toggle(.code)
        XCTAssertEqual(document.typingAttributes[.foregroundColor] as? UIColor, .label)
    }

    func testQuoteLoadsAsEditableAndPreservesInlineFormattingOnRoundTrip() {
        let source = "> A **quoted** line\n> Another line\n\nAfter"
        let document = MessageEditorDocument()
        document.load(source)
        XCTAssertFalse(document.hasUnsupportedContent)
        XCTAssertTrue(document.content.string.contains("quoted"))
        XCTAssertEqual(MessageEditorCodec.encode(MessageEditorDocument.spans(document.content)), source)
    }

    func testFormattingUsesSelectedDisplayRange() {
        let editor = MessageEditorDocument()
        editor.load("hello world")
        editor.selection = NSRange(location: 6, length: 5)
        editor.toggle(.bold)
        XCTAssertEqual(editor.markdown, "hello **world**")
        XCTAssertEqual(editor.selection, NSRange(location: 6, length: 5))
    }

    func testMentionReplacementOnlyChangesCandidateAtCaret() {
        let editor = MessageEditorDocument()
        editor.load("@same and @same")
        editor.selection = NSRange(location: 5, length: 0)
        XCTAssertEqual(editor.completion?.query, "same")
        editor.insertMarkup("[user]Alice(alice)[/user]", replacing: editor.completion?.range)
        XCTAssertEqual(editor.markdown, "[user]Alice(alice)[/user] and @same")
    }

    func testFirstBackspaceSelectsOnlyReferenceThenAllowsDeletion() {
        let editor = MessageEditorDocument()
        editor.load("before [user]Alice(alice)[/user] after")
        editor.selection = NSRange(location: 8, length: 0)
        XCTAssertEqual(editor.atomicSelectionForDeletion(NSRange(location: 7, length: 1)), NSRange(location: 7, length: 1))
        editor.selection = NSRange(location: 7, length: 1)
        XCTAssertNil(editor.atomicSelectionForDeletion(NSRange(location: 7, length: 1)))
    }

    func testFirstBackspaceSelectsOnlyLink() {
        let editor = MessageEditorDocument()
        editor.load("before [website](https://example.org) after")
        editor.selection = NSRange(location: 14, length: 0)
        XCTAssertEqual(editor.atomicSelectionForDeletion(NSRange(location: 13, length: 1)), NSRange(location: 7, length: 7))
    }

    func testCompletionUsesUTF16CaretAndIgnoresEmailAndCode() {
        let editor = MessageEditorDocument()
        editor.load("😀 @al")
        XCTAssertEqual(editor.completion?.range, NSRange(location: 3, length: 3))
        editor.load("mail@example.org")
        XCTAssertNil(editor.completion)
        editor.load("`@alice`")
        XCTAssertNil(editor.completion)
    }

    func testUnsupportedContentIsPreservedWithoutAnEditableSourceDocument() {
        for source in ["# Heading\n\n```swift\nlet x = 1\n```", #"**Equation:** $x*y*z + \alpha$"#, "<div>legacy</div>"] {
            let editor = MessageEditorDocument()
            editor.load(source)
            XCTAssertTrue(editor.hasUnsupportedContent)
            XCTAssertEqual(editor.markdown, source)
            XCTAssertEqual(editor.content.string, "")
            XCTAssertFalse(editor.canSetLink)
            XCTAssertNil(editor.completion)

            editor.insertText("!")
            editor.insertMarkup("[user]Alice(alice)[/user]")
            editor.removeMarkup(source)
            editor.toggle(.bold)
            editor.beginCompletion("@")
            editor.setLink(label: "replacement", address: "https://example.org")
            editor.accept(NSAttributedString(string: "replacement"), selection: NSRange(location: 0, length: 0))
            XCTAssertEqual(editor.markdown, source)
            XCTAssertEqual(editor.content.string, "")
        }
    }

    func testSupportedLoadRestoresEditingAfterUnsupportedContent() {
        let editor = MessageEditorDocument()
        editor.load("# Heading")
        editor.load("hello")
        XCTAssertFalse(editor.hasUnsupportedContent)
        editor.insertText("!")
        XCTAssertEqual(editor.content.string, "hello!")
        XCTAssertEqual(editor.markdown, "hello!")
    }

    func testLinkCanBeUpdatedAndUnlinkedWithoutLosingLabel() {
        let editor = MessageEditorDocument()
        editor.load("[old](https://example.org)")
        editor.selection = NSRange(location: 1, length: 0)
        editor.setLink(label: "new", address: "https://tum.de")
        XCTAssertEqual(editor.markdown, "[new](https://tum.de)")
        editor.unlink()
        XCTAssertEqual(editor.markdown, "new")
    }
    func testClipboardExportsReferenceMarkdownWithoutReplacementCharacters() {
        let editor = MessageEditorDocument()
        editor.load("[user]Alice(alice)[/user]")
        XCTAssertEqual(editor.markdown(in: NSRange(location: 0, length: 1)), "[user]Alice(alice)[/user]")
    }

    func testChangingOnlyLinkAddressPreservesMixedFormatting() {
        let editor = MessageEditorDocument()
        editor.load("[**bold** plain](https://example.org)")
        editor.selection = NSRange(location: 1, length: 0)
        editor.setLink(label: "bold plain", address: "https://tum.de")
        XCTAssertEqual(editor.markdown, "[**bold** plain](https://tum.de)")
    }

    func testSelectionExtendingOutsideLinkDoesNotEditExistingLink() {
        let editor = MessageEditorDocument()
        editor.load("[one](https://example.org) rest")
        editor.selection = NSRange(location: 1, length: 5)
        XCTAssertNil(editor.linkRange)
    }

    func testReferenceCannotBeConvertedIntoLink() {
        let editor = MessageEditorDocument()
        editor.load("[user]Alice(alice)[/user]")
        editor.selection = NSRange(location: 0, length: 1)
        editor.setLink(label: "Alice", address: "https://tum.de")
        XCTAssertEqual(editor.markdown, "[user]Alice(alice)[/user]")
        XCTAssertFalse(editor.canSetLink)
    }

    func testExplicitSelectionContainingWholeLinkDeletesNormally() {
        let editor = MessageEditorDocument()
        editor.load("before [website](https://example.org) after")
        editor.selection = NSRange(location: 0, length: editor.content.length)
        XCTAssertNil(editor.atomicSelectionForDeletion(editor.selection))
    }

    func testRelativeFileLinkIsAcceptedAndUnsafeLinkRejected() {
        let editor = MessageEditorDocument()
        editor.setLink(label: "file", address: "/api/core/files/file.pdf")
        XCTAssertEqual(editor.markdown, "[file](/api/core/files/file.pdf)")
        editor.setLink(label: "unsafe", address: "javascript:alert(1)")
        XCTAssertEqual(editor.markdown, "[file](/api/core/files/file.pdf)")
    }

    func testPlainClipboardTextUsesReadableReferenceLabels() {
        let editor = MessageEditorDocument()
        editor.load("[user]Alice(alice)[/user] [channel]general(2)[/channel]")
        XCTAssertEqual(editor.plainText(in: NSRange(location: 0, length: editor.content.length)), "@Alice #general")
    }

    func testFileLinkCanContainEncodedSpace() {
        let editor = MessageEditorDocument()
        editor.setLink(label: "file", address: "/api/core/files/my%20file.pdf")
        XCTAssertEqual(editor.markdown, "[file](/api/core/files/my%20file.pdf)")
        XCTAssertFalse(MessageEditorLinkValidation.isValid("https://example.org/%0aevil"))
    }
    func testImageRemovalUsesSemanticEditAndKeepsOtherContent() {
        let editor = MessageEditorDocument()
        editor.load("before ![image](/api/core/files/photo.png) after")
        editor.removeMarkup("![image](/api/core/files/photo.png)")
        XCTAssertEqual(editor.markdown, "before  after")
        XCTAssertEqual(editor.content.string, "before  after")
    }
    func testToolbarCompletionEstablishesCaretBoundaryForBothTriggers() {
        for trigger: Character in ["@", "#"] {
            for (text, selection, expected) in [
                ("", NSRange(location: 0, length: 0), String(trigger)),
                ("hello", NSRange(location: 5, length: 0), "hello " + String(trigger)),
                ("hello ", NSRange(location: 6, length: 0), "hello " + String(trigger)),
                ("hello", NSRange(location: 2, length: 2), "he " + String(trigger) + "o")
            ] {
                let editor = MessageEditorDocument()
                editor.load(text)
                editor.selection = selection
                editor.beginCompletion(trigger)
                XCTAssertEqual(editor.content.string, expected)
                XCTAssertEqual(editor.completion?.trigger, trigger)
                XCTAssertEqual(editor.completion?.query, "")
            }
        }
        let editor = MessageEditorDocument()
        editor.load("hello@example.org")
        XCTAssertNil(editor.completion)
    }
}
