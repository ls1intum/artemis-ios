import XCTest
@testable import Messages

@MainActor
final class MessageEditorAttachmentTests: XCTestCase {
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
