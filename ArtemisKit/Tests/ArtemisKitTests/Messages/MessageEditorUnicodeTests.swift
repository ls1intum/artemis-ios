import XCTest
@testable import Messages

final class MessageEditorUnicodeTests: XCTestCase {
    func testReferenceFollowedByCombiningTextDecodesAndRoundTrips() throws {
        for markup in ["[user]Alice(alice)[/user]", "[report](/api/files/report.pdf)", "![image](/api/files/image.png)"] {
            for suffix in ["\u{0301}", "\u{FE0F}"] {
                let source = markup + suffix
                let decoded = try XCTUnwrap(MessageEditorCodec.decode(source), source)
                XCTAssertEqual(decoded.compactMap(\.reference).map(\.markup), [markup])
                XCTAssertEqual(decoded.map(\.text).joined(), "\u{fffc}" + suffix)
                XCTAssertEqual(MessageEditorCodec.encode(decoded), source)
                XCTAssertEqual(MessageEditorCodec.decode(MessageEditorCodec.encode(decoded)), decoded)
            }
        }
    }

    func testCommonMarkFallbackRestoresReferenceBeforeCombiningText() throws {
        for markup in ["[user]Alice(alice)[/user]", "[report](/api/files/report.pdf)", "![image](/api/files/image.png)"] {
            for suffix in ["\u{0301}", "\u{FE0F}"] {
                let source = "*a **b* c** " + markup + suffix
                let decoded = try XCTUnwrap(MessageEditorCodec.decode(source), source)
                XCTAssertEqual(decoded.compactMap(\.reference).map(\.markup), [markup])
                XCTAssertEqual(decoded.map(\.text).joined(), "a b c \u{fffc}" + suffix)
                let reopened = try XCTUnwrap(MessageEditorCodec.decode(MessageEditorCodec.encode(decoded)))
                XCTAssertEqual(reopened.compactMap(\.reference).map(\.markup), [markup])
                XCTAssertEqual(reopened.map(\.text).joined(), "a b c \u{fffc}" + suffix)
            }
        }
    }

    func testCombiningSyntaxClosersPreserveEscapesAndOrdinaryGraphemes() throws {
        for source in ["]\u{0301}", ")\u{FE0F}", "café", "e\u{0301}", "1\u{FE0F}\u{20E3}", "*\u{FE0F}\u{20E3}"] {
            let decoded = try XCTUnwrap(MessageEditorCodec.decode(source), source)
            XCTAssertEqual(decoded.map(\.text).joined(), source)
            XCTAssertTrue(decoded.allSatisfy { $0.style.isEmpty && $0.reference == nil })
        }
        let escaped = try XCTUnwrap(MessageEditorCodec.decode("\\]\u{0301} \\)\u{FE0F}"))
        XCTAssertEqual(escaped.map(\.text).joined(), "]\u{0301} )\u{FE0F}")
        let emphasized = try XCTUnwrap(MessageEditorCodec.decode("**café** *e\u{0301}* **]\u{0301}**"))
        XCTAssertEqual(emphasized.map(\.text).joined(), "café e\u{0301} ]\u{0301}")
        XCTAssertEqual(emphasized.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }.map(\.style), [.bold, .italic, .bold])
        let file = try XCTUnwrap(MessageEditorCodec.decode("[a\\]\u{0301}](/api/files/a)"))
        XCTAssertEqual(file.first?.reference?.fileName, "a]\u{0301}")
    }

    func testEncodingCombiningTextAfterReferenceNeverLeaksAnInternalPlaceholder() {
        for (markup, label) in [("[user]Alice(alice)[/user]", "@Alice"), ("[report](/api/files/report.pdf)", "report"), ("![image](/api/files/image.png)", "Image: image")] {
            for suffix in ["\u{0301}", "\u{FE0F}"] {
                let spans = [
                    MessageEditorSpan(text: "\u{fffc}", reference: MessageEditorReference(markup: markup, label: label)),
                    MessageEditorSpan(text: suffix)
                ]
                XCTAssertEqual(MessageEditorCodec.encode(spans), markup + suffix)
            }
        }
    }

    func testEncodingReferencePreservesLiteralPrivateUseScalarsInsideGraphemes() throws {
        let markup = "[user]Alice(alice)[/user]"
        for suffix in ["\u{0301}", "\u{FE0F}"] {
            let literal = "\u{f0000}" + suffix + " "
            let spans = [
                MessageEditorSpan(text: literal),
                MessageEditorSpan(text: "\u{fffc}", reference: MessageEditorReference(markup: markup, label: "@Alice"))
            ]
            let source = MessageEditorCodec.encode(spans)
            XCTAssertEqual(source, literal + markup)
            let reopened = try XCTUnwrap(MessageEditorCodec.decode(source))
            XCTAssertEqual(reopened.first?.text, literal)
            XCTAssertEqual(reopened.last?.reference?.markup, markup)
        }
    }

    func testCommonMarkReferenceMarkersAvoidLiteralPrivateUseScalarsInsideGraphemes() throws {
        let markup = "[user]Alice(alice)[/user]"
        for suffix in ["\u{0301}", "\u{FE0F}"] {
            let literal = "\u{f0000}" + suffix + " "
            let source = "*a **b* c** " + literal + markup
            var scanner = MessageEditorInlineParser(source)
            let (_, references) = try scanner.protectedSource()
            XCTAssertTrue(references.keys.allSatisfy { marker in
                marker.unicodeScalars.allSatisfy { !source.unicodeScalars.contains($0) }
            })
            let decoded = try XCTUnwrap(MessageEditorCodec.decode(source))
            XCTAssertTrue(decoded.map(\.text).joined().contains(literal))
            XCTAssertEqual(decoded.compactMap(\.reference).map(\.markup), [markup])
        }
    }
}
