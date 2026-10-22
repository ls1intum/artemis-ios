import Foundation

struct MessageEditorInlineParser {
    static let escapable = Set(##"!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~"##)
    private static let referenceTags: Set<String> = [
        "user", "channel", "programming", "modeling", "quiz", "text", "file-upload",
        "lecture", "lecture-unit", "slide", "faq", "message", "post", "answer"
    ]

    private let characters: [Character]
    private var index = 0

    private enum ParseError: Error {
        case unsupported
    }

    init(_ source: String) {
        characters = Array(source)
    }

    /// Protect Artemis payloads before Foundation handles CommonMark delimiter runs.
    mutating func protectedSource() throws -> (String, [Character: [MessageEditorSpan]]) {
        var source = ""
        var references: [Character: [MessageEditorSpan]] = [:]
        var scalar = 0xf0000
        func protect(_ spans: [MessageEditorSpan]) -> String {
            while characters.contains(Character(UnicodeScalar(scalar)!)) { scalar += 1 }
            let character = Character(UnicodeScalar(scalar)!)
            references[character] = spans
            scalar += 1
            return String(character)
        }
        while index < characters.count {
            let start = index
            if matches("\\"), index + 1 < characters.count {
                index += 2
            } else if matches("`") {
                _ = try parseCode(style: [])
            } else if startsMath() {
                throw ParseError.unsupported
            } else if matches("![") {
                source += protect([try parseImage(style: [])])
                continue
            } else if matches("[") {
                if let end = find("]", from: index + 1), Self.referenceTags.contains(String(characters[(index + 1)..<end])) {
                    if let reference = try? parseReference(tag: String(characters[(index + 1)..<end]), tagEnd: end) {
                        source += protect([reference])
                        continue
                    }
                }
                let label = try bracketLabel()
                guard var labelSpans = MessageEditorCodec.decode(label), !labelSpans.isEmpty,
                      labelSpans.allSatisfy({ $0.reference == nil && $0.link == nil }) else { throw ParseError.unsupported }
                let destination = try linkDestination()
                if let file = fileReference(start: start, destination: destination, spans: labelSpans) {
                    labelSpans = [file]
                } else {
                    for offset in labelSpans.indices { labelSpans[offset].link = destination }
                }
                source += protect(labelSpans)
                continue
            } else {
                index += 1
            }
            source += String(characters[start..<index])
        }
        return (source, references)
    }

    mutating func parse(until closing: String? = nil, style: MessageEditorStyle = []) throws -> [MessageEditorSpan] {
        var spans: [MessageEditorSpan] = []
        while index < characters.count {
            if let closing, isClosing(closing, style: style) {
                if closing != "</ins>", index > 0, characters[index - 1].isWhitespace { throw ParseError.unsupported }
                index += closing.count
                guard !spans.isEmpty else { throw ParseError.unsupported }
                return spans
            }
            if matches("\\"), index + 1 < characters.count, Self.escapable.contains(characters[index + 1]) {
                index += 1
                append(MessageEditorSpan(text: String(characters[index]), style: style), to: &spans)
                index += 1
            } else if matches("`") {
                append(try parseCode(style: style), to: &spans)
            } else if matches("![") {
                append(try parseImage(style: style), to: &spans)
            } else if matches("[") {
                for span in try parseBracket(style: style) { append(span, to: &spans) }
            } else if let (delimiter, addedStyle, end) = formattingDelimiter() {
                for span in try parseFormatting(delimiter, addedStyle: addedStyle, end: end, style: style) {
                    append(span, to: &spans)
                }
            } else {
                try appendLiteral(style: style, to: &spans)
            }
        }
        guard closing == nil else { throw ParseError.unsupported }
        return spans
    }

    private mutating func parseFormatting(_ delimiter: String, addedStyle: MessageEditorStyle, end: String, style: MessageEditorStyle) throws -> [MessageEditorSpan] {
        guard !style.contains(addedStyle) else { throw ParseError.unsupported }
        index += delimiter.count
        guard index < characters.count, delimiter == "<ins>" || !characters[index].isWhitespace else { throw ParseError.unsupported }
        return try parse(until: end, style: style.union(addedStyle))
    }

    private mutating func appendLiteral(style: MessageEditorStyle, to spans: inout [MessageEditorSpan]) throws {
        guard characters[index] != "<", characters[index] != ">", characters[index] != "_" else { throw ParseError.unsupported }
        guard !startsMath() else { throw ParseError.unsupported }
        // Character entities need a complete HTML entity decoder; preserve that source instead.
        if matches("&"), let end = ((index + 1)..<min(index + 33, characters.count)).first(where: { characters[$0] == ";" }) {
            let candidate = String(characters[index...end])
            if candidate.range(of: #"^&(?:[A-Za-z][A-Za-z0-9]*|#[0-9]+|#x[0-9A-Fa-f]+);$"#, options: .regularExpression) != nil {
                throw ParseError.unsupported
            }
        }
        append(MessageEditorSpan(text: String(characters[index]), style: style), to: &spans)
        index += 1
    }

    /// Math is rendered by the web client. Keep its source intact instead of editing TeX as text.
    private func startsMath() -> Bool {
        guard matches("$") else { return false }
        if matches("$$") { return true }
        var cursor = index + 1
        while cursor < characters.count {
            if characters[cursor] == "\\", cursor + 1 < characters.count {
                cursor += 2
                continue
            }
            if characters[cursor] == "$",
               cursor + 1 == characters.count || !"0123456789".contains(characters[cursor + 1]) {
                return true
            }
            cursor += 1
        }
        return false
    }

    private func isClosing(_ delimiter: String, style: MessageEditorStyle) -> Bool {
        guard matches(delimiter) else { return false }
        // Inside italic text, a pair starts nested bold unless bold is already active.
        return delimiter != "*" || !matches("**") || style.contains(.bold)
    }

    private func formattingDelimiter() -> (String, MessageEditorStyle, String)? {
        if matches("**") { return ("**", .bold, "**") }
        if matches("*") { return ("*", .italic, "*") }
        if matches("~~") { return ("~~", .strikethrough, "~~") }
        if matches("<ins>") { return ("<ins>", .underline, "</ins>") }
        // Foundation handles underscore emphasis and its additional intraword rules.
        return nil
    }

    private mutating func parseCode(style: MessageEditorStyle) throws -> MessageEditorSpan {
        let start = index
        while index < characters.count && characters[index] == "`" { index += 1 }
        let length = index - start
        let contentStart = index
        while index < characters.count {
            if characters[index] != "`" { index += 1; continue }
            let runStart = index
            while index < characters.count && characters[index] == "`" { index += 1 }
            guard index - runStart == length else { continue }
            var text = String(characters[contentStart..<runStart])
            guard !text.contains("\n"), !text.contains("\r") else { throw ParseError.unsupported }
            if text.hasPrefix(" ") && text.hasSuffix(" ") && text.contains(where: { $0 != " " }) {
                text.removeFirst()
                text.removeLast()
            }
            guard !text.isEmpty else { throw ParseError.unsupported }
            return MessageEditorSpan(text: text, style: style.union(.code))
        }
        throw ParseError.unsupported
    }

    private mutating func parseBracket(style: MessageEditorStyle) throws -> [MessageEditorSpan] {
        if let tagEnd = find("]", from: index + 1) {
            let tag = String(characters[(index + 1)..<tagEnd])
            if Self.referenceTags.contains(tag), var reference = try? parseReference(tag: tag, tagEnd: tagEnd) {
                reference.style = style
                return [reference]
            }
        }
        let start = index
        let label = try bracketLabel()
        let destination = try linkDestination()
        var parser = Self(label)
        var spans = try parser.parse(style: style)
        guard !spans.isEmpty, spans.allSatisfy({ $0.link == nil && $0.reference == nil }) else { throw ParseError.unsupported }
        if let file = fileReference(start: start, destination: destination, spans: spans) {
            var file = file
            file.style = style
            return [file]
        }
        for offset in spans.indices { spans[offset].link = destination }
        return spans
    }

    private func fileReference(start: Int, destination: String, spans: [MessageEditorSpan]) -> MessageEditorSpan? {
        guard URLComponents(string: destination)?.path.contains("/files/") == true else { return nil }
        let title = spans.map(\.text).joined()
        let reference = MessageEditorReference(markup: String(characters[start..<index]), label: title,
                                               fileName: title, filePath: destination)
        return MessageEditorSpan(text: "\u{fffc}", reference: reference)
    }

    private mutating func parseReference(tag: String, tagEnd: Int) throws -> MessageEditorSpan {
        let closing = "[/\(tag)]"
        guard let end = find(closing, from: tagEnd + 1) else { throw ParseError.unsupported }
        let body = Array(characters[(tagEnd + 1)..<end])
        guard body.last == ")" else { throw ParseError.unsupported }
        var depth = 1
        var opening = body.count - 2
        while opening >= 0 {
            if body[opening] == ")" { depth += 1 }
            if body[opening] == "(" { depth -= 1 }
            if depth == 0 { break }
            opening -= 1
        }
        guard opening > 0, opening + 1 < body.count - 1 else { throw ParseError.unsupported }
        let title = String(body[..<opening])
        guard !body.contains("\n"), !body.contains("\r") else { throw ParseError.unsupported }
        let prefix = tag == "user" ? "@" : (tag == "channel" ? "#" : "")
        let markup = String(characters[index..<(end + closing.count)])
        index = end + closing.count
        return MessageEditorSpan(text: "\u{FFFC}", reference: MessageEditorReference(markup: markup, label: prefix + title))
    }

    private mutating func parseImage(style: MessageEditorStyle) throws -> MessageEditorSpan {
        let start = index
        index += 1
        let label = try bracketLabel()
        let path = try linkDestination()
        let markup = String(characters[start..<index])
        var labelParser = Self(label)
        let labelSpans = try labelParser.parse()
        guard labelSpans.allSatisfy({ $0.reference == nil && $0.link == nil }) else { throw ParseError.unsupported }
        let title = labelSpans.map(\.text).joined()
        let reference = MessageEditorReference(markup: markup, label: "Image: " + title, imageName: title, imagePath: path)
        return MessageEditorSpan(text: "\u{FFFC}", style: style, reference: reference)
    }

    private mutating func bracketLabel() throws -> String {
        guard matches("[") else { throw ParseError.unsupported }
        index += 1
        let start = index
        var depth = 1
        while index < characters.count {
            if matches("\\"), index + 1 < characters.count { index += 2; continue }
            if matches("[") { depth += 1 }
            if matches("]") { depth -= 1 }
            if depth == 0 {
                let label = String(characters[start..<index])
                index += 1
                return label
            }
            index += 1
        }
        throw ParseError.unsupported
    }

    private mutating func linkDestination() throws -> String {
        guard matches("(") else { throw ParseError.unsupported }
        index += 1
        var depth = 1
        var destination = ""
        while index < characters.count {
            let character = characters[index]
            guard !character.isWhitespace, character != "<", character != ">", character != "\"" else { throw ParseError.unsupported }
            if matches("\\"), index + 1 < characters.count, Self.escapable.contains(characters[index + 1]) {
                index += 1
                destination.append(characters[index])
            } else {
                if character == "(" { depth += 1 }
                if character == ")" { depth -= 1 }
                if depth == 0 {
                    index += 1
                    guard isSafeDestination(destination) else { throw ParseError.unsupported }
                    return destination
                }
                destination.append(character)
            }
            index += 1
        }
        throw ParseError.unsupported
    }

    private func isSafeDestination(_ destination: String) -> Bool {
        guard let decoded = destination.removingPercentEncoding,
              !decoded.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains),
              let components = URLComponents(string: destination) else { return false }
        if destination.hasPrefix("/api/") || destination.hasPrefix("/courses/") { return true }
        switch components.scheme?.lowercased() {
        case "https", "http": return components.host?.isEmpty == false
        case "mailto": return !components.path.isEmpty
        default: return false
        }
    }

    private func matches(_ token: String) -> Bool {
        characters[index...].starts(with: token)
    }

    private func find(_ token: String, from start: Int) -> Int? {
        guard start <= characters.count else { return nil }
        return (start..<characters.count).first { characters[$0...].starts(with: token) }
    }

    private func append(_ span: MessageEditorSpan, to spans: inout [MessageEditorSpan]) {
        if let last = spans.last, last.style == span.style, last.link == span.link, last.reference == nil, span.reference == nil {
            spans[spans.count - 1].text += span.text
        } else {
            spans.append(span)
        }
    }
}
