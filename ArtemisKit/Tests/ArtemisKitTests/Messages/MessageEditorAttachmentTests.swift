import XCTest
@testable import Messages

@MainActor
final class MessageEditorAttachmentTests: XCTestCase {
    func testAdjacentCopiesOfTheSameFileCanBeRenamedAndRemovedIndividually() throws {
        let editor = MessageEditorDocument()
        editor.load("[one](/api/files/file.pdf)[two](/api/files/file.pdf)")
        XCTAssertEqual(editor.attachments.count, 2)
        let first = try XCTUnwrap(editor.attachments.first)
        XCTAssertTrue(editor.renameAttachment(first, to: "Renamed"))
        XCTAssertEqual(editor.attachments.map(\.name), ["Renamed", "two"])
        editor.removeAttachment(try XCTUnwrap(editor.attachments.first))
        XCTAssertEqual(editor.markdown, "[two](/api/files/file.pdf)")
    }

    func testStyledAttachmentsKeepTheirEnclosingMarksAfterEditingAndRenaming() throws {
        for prefix in ["", "!"] {
            for (open, close) in [("**", "**"), ("*", "*"), ("<ins>", "</ins>"), ("~~", "~~")] {
                let editor = MessageEditorDocument()
                let source = open + prefix + "[report](/api/files/a)" + close + " rest"
                editor.load(source)
                editor.insertText("!")
                XCTAssertEqual(editor.markdown, source + "!")
                XCTAssertTrue(editor.renameAttachment(try XCTUnwrap(editor.attachments.first), to: "Renamed"))
                XCTAssertEqual(editor.markdown, open + prefix + "[Renamed](/api/files/a)" + close + " rest!")
            }
        }
    }

    func testAttachmentNamesThatMatchReferenceTagsReopenNormally() throws {
        for name in ["text", "user", "lecture", "message", "file-upload"] {
            let editor = MessageEditorDocument()
            editor.load("[original](/api/files/a)")
            XCTAssertTrue(editor.renameAttachment(try XCTUnwrap(editor.attachments.first), to: name))
            let reopened = MessageEditorDocument()
            reopened.load(editor.markdown)
            XCTAssertFalse(reopened.hasUnsupportedContent, name)
            XCTAssertEqual(reopened.attachments.first?.name, name)
            XCTAssertEqual(reopened.attachments.first?.path, "/api/files/a")
        }
    }

    func testEmphasisAcrossAttachmentBoundariesRendersWithoutLiteralDelimiters() throws {
        for (open, close, intent) in [("**", "**", InlinePresentationIntent.stronglyEmphasized), ("*", "*", .emphasized)] {
            let editor = MessageEditorDocument()
            editor.load(open + "before[report](/api/files/a)after" + close)
            editor.insertText("!")
            let rendered = try AttributedString(markdown: editor.markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
            XCTAssertEqual(String(rendered.characters), "beforereportafter!")
            for run in rendered.runs where !String(rendered[run.range].characters).contains("!") {
                XCTAssertEqual(run.inlinePresentationIntent?.contains(intent), true)
            }
        }
    }

    func testFileRenamePreservesURLAndSurroundingFormatting() throws {
        let editor = MessageEditorDocument()
        let path = "/api/core/files/attachments/1/original.pdf"
        editor.load("**Before** [original.pdf](\(path)) after")
        let attachment = try XCTUnwrap(editor.attachments.first)
        XCTAssertFalse(attachment.isImage)
        XCTAssertEqual(attachment.name, "original.pdf")
        XCTAssertTrue(editor.renameAttachment(attachment, to: "Report [final].pdf"))
        XCTAssertEqual(editor.markdown, "**Before** [Report \\[final\\].pdf](\(path)) after")
        XCTAssertEqual(editor.attachments.first?.path, path)
        let reopened = MessageEditorDocument()
        reopened.load(editor.markdown)
        XCTAssertEqual(reopened.attachments.first?.name, "Report [final].pdf")
    }

    func testImageRenameChangesOnlyTheSelectedOccurrenceAndSurvivesReload() throws {
        let editor = MessageEditorDocument()
        let source = "![same](/api/files/one.png) ![same](/api/files/two.png)"
        editor.load(source)
        let attachment = try XCTUnwrap(editor.attachments.last)
        XCTAssertTrue(attachment.isImage)
        XCTAssertTrue(editor.renameAttachment(attachment, to: "Diagram [2] 😀"))
        XCTAssertEqual(editor.markdown, "![same](/api/files/one.png) ![Diagram \\[2\\] 😀](/api/files/two.png)")
        let reopened = MessageEditorDocument()
        reopened.load(editor.markdown)
        XCTAssertFalse(reopened.hasUnsupportedContent)
        XCTAssertEqual(reopened.attachments.map(\.name), ["same", "Diagram [2] 😀"])
        XCTAssertEqual(reopened.attachments.map(\.path), ["/api/files/one.png", "/api/files/two.png"])
    }

    func testBlankMultilineAndStaleRenamesLeaveTheDocumentUntouched() throws {
        let editor = MessageEditorDocument()
        editor.load("[file](/api/files/file.pdf)")
        let attachment = try XCTUnwrap(editor.attachments.first)
        for invalid in ["", "   ", "two\nlines"] {
            XCTAssertFalse(editor.renameAttachment(attachment, to: invalid))
            XCTAssertEqual(editor.markdown, "[file](/api/files/file.pdf)")
        }
        editor.load("Different text")
        XCTAssertFalse(editor.renameAttachment(attachment, to: "renamed"))
        XCTAssertEqual(editor.markdown, "Different text")
    }

    func testOrdinaryLinksAreNotListedAsFileUploads() {
        let editor = MessageEditorDocument()
        editor.load("[website](https://example.org) [course](/courses/1) [file](/api/files/report.pdf)")
        XCTAssertEqual(editor.attachments.map(\.name), ["file"])
    }
}
