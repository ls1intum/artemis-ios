import Foundation

struct MessageEditorStyle: OptionSet {
    let rawValue: Int

    static let bold = Self(rawValue: 1 << 0)
    static let italic = Self(rawValue: 1 << 1)
    static let underline = Self(rawValue: 1 << 2)
    static let strikethrough = Self(rawValue: 1 << 3)
    static let code = Self(rawValue: 1 << 4)
}

struct MessageEditorReference: Equatable {
    let markup: String
    let label: String
    var imageName: String?
    var imagePath: String?
    var fileName: String?
    var filePath: String?
}

struct MessageEditorSpan: Equatable {
    var text: String
    var style: MessageEditorStyle = []
    var link: String?
    var reference: MessageEditorReference?
    var block: MessageEditorBlock?
}

/// A deliberately small inline Markdown dialect. Unsupported content cannot be edited;
/// returning nil prevents changing a legacy message while hydrating an edit or draft.
struct MessageEditorCodec {
    static func decode(_ markdown: String) -> [MessageEditorSpan]? {
        if markdown.range(of: #"(?m)^(?:>|[-+*] |[0-9]{1,9}[.)] |`{3,}|~{3,})"#, options: .regularExpression) != nil {
            return MessageEditorBlockCodec.decode(markdown, inline: decodeInline)
        }
        return decodeInline(markdown)
    }

    private static func decodeInline(_ markdown: String) -> [MessageEditorSpan]? {
        guard !hasUnsupportedBlock(markdown) else { return nil }
        var parser = MessageEditorInlineParser(markdown)
        return (try? parser.parse()) ?? MessageEditorCommonMark.decode(markdown)
    }

    static func encode(_ spans: [MessageEditorSpan]) -> String {
        if spans.contains(where: { $0.block != nil }) { return MessageEditorBlockCodec.encode(spans, inline: encodeInline) }
        return encodeInline(spans)
    }

    private static func encodeInline(_ spans: [MessageEditorSpan]) -> String {
        var result = ""
        var pending: [MessageEditorSpan] = []
        func flush() {
            guard !pending.isEmpty else { return }
            let content = MessageEditorEmphasis.encode(pending) { encodeStyles($0, level: 2) } ?? encodeStyles(pending, level: 0)
            if let link = pending.first?.link {
                result += content.components(separatedBy: "\n").map { line in
                    line.isEmpty ? "" : "[\(line)](\(escapeDestination(link)))"
                }.joined(separator: "\n")
            } else {
                result += content
            }
            pending.removeAll()
        }
        // Protect atomic payloads while emphasis is encoded across their boundaries.
        // Wrapping each atom separately can create ambiguous adjacent CommonMark delimiters.
        let source = spans.map { $0.reference?.markup ?? $0.text }.joined()
        var scalar: UInt32 = 0xf0000
        var references: [(String, String)] = []
        for var span in spans where !span.text.isEmpty {
            if let reference = span.reference {
                while source.unicodeScalars.contains(UnicodeScalar(scalar)!) { scalar += 1 }
                let marker = String(UnicodeScalar(scalar)!)
                scalar += 1
                references.append((marker, reference.markup))
                span.text = marker
                span.reference = nil
            }
            if let previous = pending.last, previous.link != span.link { flush() }
            pending.append(span)
        }
        flush()
        for (marker, markup) in references { result = result.replacingOccurrences(of: marker, with: markup) }
        return result
    }

    private static let delimiters: [(MessageEditorStyle, String, String)] = [
        (.bold, "**", "**"), (.italic, "*", "*"), (.underline, "<ins>", "</ins>"), (.strikethrough, "~~", "~~")
    ]

    private static func encodeStyles(_ spans: [MessageEditorSpan], level: Int) -> String {
        guard level < delimiters.count else {
            return encodeCode(spans)
        }
        let (style, opening, closing) = delimiters[level]
        var result = ""
        var index = 0
        while index < spans.count {
            let active = spans[index].style.contains(style)
            let start = index
            repeat { index += 1 } while index < spans.count && spans[index].style.contains(style) == active
            let content = encodeStyles(Array(spans[start..<index]), level: level + 1)
            result += active ? wrapInline(content, opening: opening, closing: closing) : content
        }
        return result
    }

    private static func wrapInline(_ content: String, opening: String, closing: String) -> String {
        content.components(separatedBy: "\n").map { line in
            guard let start = line.firstIndex(where: { !$0.isWhitespace }),
                  let last = line.lastIndex(where: { !$0.isWhitespace }) else { return line }
            let end = line.index(after: last)
            return String(line[..<start]) + opening + line[start..<end] + closing + line[end...]
        }.joined(separator: "\n")
    }

    private static func encodeCode(_ spans: [MessageEditorSpan]) -> String {
        var result = ""
        var index = 0
        while index < spans.count {
            let isCode = spans[index].style.contains(.code)
            var text = ""
            repeat {
                text += spans[index].text
                index += 1
            } while index < spans.count && spans[index].style.contains(.code) == isCode
            if isCode {
                var line = ""
                for character in text {
                    if character.isNewline {
                        result += encodeCodeLine(line) + String(character)
                        line = ""
                    } else {
                        line.append(character)
                    }
                }
                result += encodeCodeLine(line)
            } else {
                result += escapeText(text)
            }
        }
        return result
    }

    private static func encodeCodeLine(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        let longestRun = text.split(whereSeparator: { $0 != "`" }).map(\.count).max() ?? 0
        let delimiter = String(repeating: "`", count: longestRun + 1)
        let needsPadding = text.hasPrefix("`") || text.hasSuffix("`")
            || (text.hasPrefix(" ") && text.hasSuffix(" ") && text.contains(where: { $0 != " " }))
        let content = needsPadding ? " " + text + " " : text
        return delimiter + content + delimiter
    }

    private static func escapeText(_ text: String) -> String {
        let alwaysEscaped = Set(#"\`*_[]<>~|&$"#)
        let characters = Array(text)
        var result = ""
        var atLineStart = true
        var onlyIndentAndDigits = true
        var hasDigits = false
        for (offset, character) in characters.enumerated() {
            var startsBlock = false
            if atLineStart && "#-+!=".contains(character) {
                startsBlock = String(characters[offset...]).range(
                    of: #"^(?:#{1,6}(?:\s|$)|[-+](?:\s|$)|!\s|=[ \t]*(?:\r?\n|$)|[-=]{2,}(?:\s|$))"#,
                    options: .regularExpression) != nil
            }
            let startsNumberedList = (character == "." || character == ")")
                && onlyIndentAndDigits && hasDigits
                && offset + 1 < characters.count && characters[offset + 1].isWhitespace
            if alwaysEscaped.contains(character) || startsBlock || startsNumberedList { result += "\\" }
            result.append(character)
            if character == "\n" {
                atLineStart = true
                onlyIndentAndDigits = true
                hasDigits = false
            } else {
                if character.isNumber { hasDigits = true } else if !atLineStart || !character.isWhitespace { onlyIndentAndDigits = false }
                atLineStart = atLineStart && character.isWhitespace
            }
        }
        return result
    }

    private static func escapeDestination(_ destination: String) -> String {
        destination.reduce(into: "") { result, character in
            if character == "\\" || character == "(" || character == ")" { result += "\\" }
            result.append(character)
        }
    }

    private static func hasUnsupportedBlock(_ text: String) -> Bool {
        let pattern = #"(?m)^(?: {0,3}(?:#{1,6}(?:\s|$)|>|[-+](?:\s|$)|\*\s|\d+[.)]\s|`{3,}[^`\r\n]*$|~{3}|\||\[[^\]\n]+\]:|(?:[-*_]\s*){3,}$)|(?: {4}|\t)\S)"#
        let setext = #"(?m)^.*\S.*\r?\n {0,3}[=-]+[ \t]*\r?$"#
        return text.range(of: pattern, options: .regularExpression) != nil || text.range(of: setext, options: .regularExpression) != nil
    }
}
