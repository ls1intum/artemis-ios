import XCTest
@testable import Messages

final class MessageEditorCodecTests: XCTestCase {
    func testDecodesInlineFormattingAndBalancedLinkDestination() throws {
        let markdown = "**Bold** *italic* ~~removed~~ <ins>underlined</ins> `a*b` [site](https://example.org/a_(b))"
        let spans = try XCTUnwrap(MessageEditorCodec.decode(markdown))

        XCTAssertEqual(spans.filter { !$0.style.isEmpty }.map(\.text), ["Bold", "italic", "removed", "underlined", "a*b"])
        XCTAssertEqual(spans.filter { !$0.style.isEmpty }.map(\.style), [.bold, .italic, .strikethrough, .underline, .code])
        XCTAssertEqual(spans.last?.link, "https://example.org/a_(b)")
        XCTAssertEqual(spans.last?.text, "site")
        XCTAssertEqual(MessageEditorCodec.decode(MessageEditorCodec.encode(spans)), spans)
    }

    func testPreservesExactReferenceMarkupAndReadableLabels() throws {
        let references = [
            "[user]Ada (Teaching Assistant)(ada)[/user]",
            "[channel]help-and-questions(42)[/channel]",
            "[programming]Trees (Part 1) & Graphs(/courses/1/exercises/2)[/programming]",
            "[lecture-unit]Introduction (slides)(17)[/lecture-unit]",
            "[faq]How does (this) work?(/courses/1/faq?faqId=8)[/faq]"
        ]
        let spans = try XCTUnwrap(MessageEditorCodec.decode(references.joined(separator: " ")))
        let tokens = spans.filter { $0.reference != nil }

        XCTAssertEqual(tokens.map(\.text), Array(repeating: "\u{FFFC}", count: references.count))
        XCTAssertEqual(tokens.compactMap { $0.reference?.markup }, references)
        XCTAssertEqual(tokens.compactMap { $0.reference?.label }, [
            "@Ada (Teaching Assistant)", "#help-and-questions", "Trees (Part 1) & Graphs", "Introduction (slides)", "How does (this) work?"
        ])
        XCTAssertEqual(MessageEditorCodec.encode(spans), references.joined(separator: " "))
    }

    func testPreservesImagesWithNestedParentheses() throws {
        let markdown = "![Diagram (draft)](/api/files/diagram(2).png)"
        let spans = try XCTUnwrap(MessageEditorCodec.decode(markdown))

        XCTAssertEqual(spans.count, 1)
        XCTAssertEqual(spans.first?.reference?.label, "Image: Diagram (draft)")
        XCTAssertEqual(MessageEditorCodec.encode(spans), markdown)
    }

    func testEscapesTypedMarkdownWithoutChangingTextOrEmoji() throws {
        let text = "👩🏽‍💻 e\u{301} **literal** _words_ [x](y) ! <tag> &amp; # title\n1. item\n- item\\path"
        let spans = [MessageEditorSpan(text: text)]

        let decoded = try XCTUnwrap(MessageEditorCodec.decode(MessageEditorCodec.encode(spans)))
        XCTAssertEqual(decoded, spans)
        XCTAssertEqual((decoded[0].text as NSString).length, (text as NSString).length)
    }

    func testCombinedFormattingAndStyledLinksRoundTrip() throws {
        let spans = [
            MessageEditorSpan(text: "bold and italic", style: [.bold, .italic]),
            MessageEditorSpan(text: " "),
            MessageEditorSpan(text: "a*b", style: [.bold, .underline, .strikethrough]),
            MessageEditorSpan(text: " "),
            MessageEditorSpan(text: "visit", style: .italic, link: "https://example.org/(path)?q=1")
        ]

        XCTAssertEqual(MessageEditorCodec.decode(MessageEditorCodec.encode(spans)), spans)
    }

    func testCodeContainingBackticksUsesLongerDelimiter() throws {
        let spans = [MessageEditorSpan(text: "a`b ** literal", style: .code)]

        XCTAssertEqual(MessageEditorCodec.decode(MessageEditorCodec.encode(spans)), spans)
    }

    func testUnsupportedOrAmbiguousSourceUsesLosslessFallback() {
        let sources = [
            "# Heading", "- list item", "1. numbered", "> quote", "```swift\ncode\n```",
            "| a | b |\n| --- | --- |", "heading\n===", "    indented code",
            "<em>legacy</em>", "[label](url \"title\")", "[reference][id]", "[id]: /target",
            "**unfinished", "[unknown]title(1)[/unknown]", "[user]malformed[/user]", "~~unfinished"
        ]

        for source in sources {
            XCTAssertNil(MessageEditorCodec.decode(source), "Must preserve unsupported source: \(source)")
        }
    }

    func testEmptyAndMultilinePlainText() {
        XCTAssertEqual(MessageEditorCodec.decode(""), [])
        let text = "First paragraph\n\nSecond paragraph."
        XCTAssertEqual(MessageEditorCodec.decode(text), [MessageEditorSpan(text: text)])
    }

    func testLiteralEscapesAndRepeatedReferences() throws {
        let reference = "[user]Ada(ada)[/user]"
        let source = "\\*literal\\* \\[text\\] " + reference + " " + reference
        let spans = try XCTUnwrap(MessageEditorCodec.decode(source))

        XCTAssertEqual(spans.first?.text, "*literal* [text] ")
        XCTAssertEqual(spans.filter { $0.reference != nil }.count, 2)
        XCTAssertEqual(MessageEditorCodec.decode(MessageEditorCodec.encode(spans)), spans)
    }

    func testOrdinaryMentionQueriesAreUnchangedByEncoding() {
        let text = "@Ada then #one and @Grace"
        XCTAssertEqual(MessageEditorCodec.encode([MessageEditorSpan(text: text)]), text)
        XCTAssertEqual(MessageEditorCodec.encode([MessageEditorSpan(text: "# heading")]), "\\# heading")
    }

    func testFormattingTransitionsShareOuterDelimiter() {
        let spans = [
            MessageEditorSpan(text: "one", style: .bold),
            MessageEditorSpan(text: "two", style: [.bold, .italic]),
            MessageEditorSpan(text: "three", style: .bold)
        ]
        XCTAssertEqual(MessageEditorCodec.decode(MessageEditorCodec.encode(spans)), spans)
    }

    func testWhitespaceCannotCreateInvalidEmphasis() {
        XCTAssertNil(MessageEditorCodec.decode("** invalid**"))
        XCTAssertNil(MessageEditorCodec.decode("**invalid **"))
        XCTAssertEqual(MessageEditorCodec.encode([MessageEditorSpan(text: " bold ", style: .bold)]), " **bold** ")
    }

    func testRejectsUnsafeOrMalformedLinkDestinations() {
        for address in ["javascript:alert(1)", "data:text/html,test", "https:missing-host", "//example.org/path", "https://example.org/%0Aheader", "https://example.org/\u{0001}"] {
            XCTAssertNil(MessageEditorCodec.decode("[label](\(address))"), address)
        }
        for address in ["https://example.org", "http://example.org", "mailto:ada@example.org", "/api/files/test.pdf", "/courses/1/exercises/2"] {
            XCTAssertEqual(MessageEditorCodec.decode("[label](\(address))")?.first?.link, address)
        }
    }

    func testCodeDelimiterPaddingPreservesLiteralContent() {
        for text in ["`x", "x`", " a ", "``", "a``b", "   "] {
            let spans = [MessageEditorSpan(text: text, style: .code)]
            XCTAssertEqual(MessageEditorCodec.decode(MessageEditorCodec.encode(spans)), spans, text)
        }
    }

    func testEncodedSpacesInDestinationsRemainValid() {
        for address in ["https://example.org/my%20file.pdf", "/api/files/my%20file.pdf"] {
            let source = "[attachment](\(address))"
            XCTAssertEqual(MessageEditorCodec.decode(source)?.first?.link, address)
            XCTAssertEqual(MessageEditorCodec.decode(source).map(MessageEditorCodec.encode), source)
        }
        for address in ["https://example.org/my file.pdf", "/api/files/my\tfile.pdf", "/api/files/my%09file.pdf", "/api/files/my%0Dfile.pdf"] {
            XCTAssertNil(MessageEditorCodec.decode("[attachment](\(address))"), address)
        }
    }
    func testMultilineInlineCodeRoundTripsWithoutLegacyFallback() throws {
        let source = MessageEditorCodec.encode([MessageEditorSpan(text: "first\nsecond\n\nthird", style: .code)])
        let spans = try XCTUnwrap(MessageEditorCodec.decode(source))
        XCTAssertEqual(spans.map(\.text).joined(), "first\nsecond\n\nthird")
        XCTAssertEqual(source, "`first`\n`second`\n\n`third`")
    }

    func testMultilineBoldCodePreservesTextAndLineEndings() throws {
        let text = "first\r\nsecond\nthird"
        let source = MessageEditorCodec.encode([MessageEditorSpan(text: text, style: [.bold, .code])])
        let spans = try XCTUnwrap(MessageEditorCodec.decode(source))
        XCTAssertEqual(spans.map(\.text).joined(), text)
        XCTAssertEqual(source, "**`first`**\r\n**`second`**\n**`third`**")
    }
    func testOverlappingItalicThenBoldMatchesCommonMark() throws {
        try assertEmphasisRoundTrip([.italic, [.bold, .italic], .bold])
    }

    func testOverlappingBoldThenItalicMatchesCommonMark() throws {
        try assertEmphasisRoundTrip([.bold, [.bold, .italic], .italic])
    }

    func testAdjacentAndCrossingEmphasisWithIntrawordContext() throws {
        let styles: [MessageEditorStyle] = [[], .bold, .italic, [.bold, .italic]]
        for first in styles {
            for second in styles {
                for third in styles { try assertEmphasisRoundTrip([first, second, third]) }
            }
        }
    }

    private func assertEmphasisRoundTrip(_ styles: [MessageEditorStyle], file: StaticString = #filePath, line: UInt = #line) throws {
        var spans = [MessageEditorSpan(text: "z")]
        for (offset, style) in styles.enumerated() {
            spans.append(MessageEditorSpan(text: String(UnicodeScalar(97 + offset)!), style: style))
        }
        spans.append(MessageEditorSpan(text: "d"))
        let source = MessageEditorCodec.encode(spans)
        let decoded = try XCTUnwrap(MessageEditorCodec.decode(source), source, file: file, line: line)
        XCTAssertEqual(emphasisCharacters(decoded), emphasisCharacters(spans), source, file: file, line: line)
        let native = try AttributedString(markdown: source, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        var rendered: [String] = []
        for run in native.runs {
            let intent = run.inlinePresentationIntent ?? []
            let style = (intent.contains(.stronglyEmphasized) ? 1 : 0) + (intent.contains(.emphasized) ? 2 : 0)
            rendered += native[run.range].characters.map { "\($0):\(style)" }
        }
        XCTAssertEqual(rendered, emphasisCharacters(spans), source, file: file, line: line)
    }

    private func emphasisCharacters(_ spans: [MessageEditorSpan]) -> [String] {
        spans.flatMap { span in
            let style = (span.style.contains(.bold) ? 1 : 0) + (span.style.contains(.italic) ? 2 : 0)
            return span.text.map { "\($0):\(style)" }
        }
    }
    func testCrossingEmphasisInsideLinkPreservesAddressAndMarks() throws {
        let spans = [
            MessageEditorSpan(text: "z", link: "https://example.org"),
            MessageEditorSpan(text: "a", style: .italic, link: "https://example.org"),
            MessageEditorSpan(text: "b", style: [.bold, .italic], link: "https://example.org"),
            MessageEditorSpan(text: "c", style: .bold, link: "https://example.org"),
            MessageEditorSpan(text: "q", link: "https://example.org")
        ]
        XCTAssertEqual(MessageEditorCodec.decode(MessageEditorCodec.encode(spans)), spans)
    }

    func testCrossingEmphasisPreservesUnderlineAndAtomicReference() {
        let spans = [
            MessageEditorSpan(text: "z"), MessageEditorSpan(text: "a", style: .italic),
            MessageEditorSpan(text: "b", style: [.bold, .italic, .underline]), MessageEditorSpan(text: "c", style: .bold),
            MessageEditorSpan(text: "q"),
            MessageEditorSpan(text: "\u{fffc}", reference: MessageEditorReference(markup: "[user]Alice(alice)[/user]", label: "@Alice"))
        ]
        XCTAssertEqual(MessageEditorCodec.decode(MessageEditorCodec.encode(spans)), spans)
    }

    func testCommonMarkFallbackStillRejectsUnsafeAndNestedReferenceLinks() {
        for destination in ["javascript:alert(1)", "data:text/html,test", "custom:target"] {
            XCTAssertNil(MessageEditorCodec.decode("**safe** <\(destination)>"))
        }
        for label in ["[user]Alice(alice)[/user]", "![image](/api/files/test.png)"] {
            XCTAssertNil(MessageEditorCodec.decode("**safe** [\(label)](https://example.org)"))
        }
    }
}
