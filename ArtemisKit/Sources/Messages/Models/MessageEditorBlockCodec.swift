import Foundation

enum MessageEditorBlockStyle: String {
    case bulletList
    case numberedList
    case codeBlock
    case quote
}

struct MessageEditorBlock: Equatable {
    var style: MessageEditorBlockStyle
    var language = ""
    var identifier = 0
    var isEmpty = false
}

/// Flat lists and fenced code retain their paragraph semantics independently of inline marks.
/// Nested lists, task lists and continuation paragraphs stay read-only rather than being flattened.
enum MessageEditorBlockCodec {
    static func decode(_ source: String, inline: (String) -> [MessageEditorSpan]?) -> [MessageEditorSpan]? {
        let lines = lines(source)
        var result: [MessageEditorSpan] = []
        var plain = ""
        var index = 0
        var codeIdentifier = 0
        var previousWasList = false
        while index < lines.count {
            let line = lines[index]
            if let opening = fence(line) {
                guard let prefix = inline(plain) else { return nil }
                append(prefix, to: &result)
                plain = ""
                index += 1
                var body = ""
                while index < lines.count && !closesFence(lines[index], opening: opening) {
                    body += lines[index]
                    index += 1
                }
                guard index < lines.count else { return nil }
                codeIdentifier += 1
                append([MessageEditorSpan(text: body.isEmpty ? "\n" : body, style: .code,
                                          block: MessageEditorBlock(style: .codeBlock, language: opening.info, identifier: codeIdentifier, isEmpty: body.isEmpty))], to: &result)
                previousWasList = false
            } else if let marker = listMarker(line) ?? quoteMarker(line) {
                let preceding = plain.components(separatedBy: "\n")
                let interrupts = preceding.count > 1 && !preceding[preceding.count - 2].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                guard !interrupts || canInterruptParagraph(style: marker.style, line: marker.display, body: marker.body) else { return nil }
                guard let prefix = inline(plain), !marker.body.hasPrefix("[ ] "),
                      !marker.body.hasPrefix("[x] "), !marker.body.hasPrefix("[X] "),
                      let body = inline(marker.body) else { return nil }
                append(prefix, to: &result)
                plain = ""
                let block = MessageEditorBlock(style: marker.style)
                append([MessageEditorSpan(text: marker.display, block: block)], to: &result)
                append(body.map { span in
                    var copy = span
                    copy.block = block
                    return copy
                }, to: &result)
                previousWasList = true
            } else {
                let blank = line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                guard !previousWasList || blank else { return nil }
                if !blank && line.first?.isWhitespace == true { return nil }
                plain += line
                previousWasList = false
            }
            index += 1
        }
        guard let suffix = inline(plain) else { return nil }
        append(suffix, to: &result)
        return result
    }

    static func encode(_ spans: [MessageEditorSpan], inline: ([MessageEditorSpan]) -> String) -> String {
        var result = ""
        var pending: [MessageEditorSpan] = []
        var previousStyle: MessageEditorBlockStyle?
        func flush() {
            guard !pending.isEmpty else { return }
            let plain = inline(pending)
            if let previousStyle, previousStyle != .codeBlock, !plain.isEmpty {
                let trailing = result.reversed().prefix(while: { $0 == "\n" }).count
                let leading = plain.prefix(while: { $0 == "\n" }).count
                if trailing + leading < 2 { result += String(repeating: "\n", count: 2 - trailing - leading) }
            }
            result += plain
            pending = []
            previousStyle = nil
        }
        var index = 0
        while index < spans.count {
            guard let block = spans[index].block else {
                pending.append(spans[index])
                index += 1
                continue
            }
            flush()
            var group: [MessageEditorSpan] = []
            repeat {
                group.append(spans[index])
                index += 1
            } while index < spans.count && spans[index].block == block
            if block.style == .codeBlock {
                let displayed = group.map(\.text).joined()
                let body = block.isEmpty && displayed == "\n" ? "" : displayed
                let marker: Character = block.language.contains("`") ? "~" : "`"
                let longest = body.split(whereSeparator: { $0 != marker }).map(\.count).max() ?? 0
                let delimiter = String(repeating: String(marker), count: max(3, longest + 1))
                if !result.isEmpty && result.utf16.last != 10 { result += "\n" }
                result += delimiter + block.language + "\n" + body
                if !body.isEmpty && body.utf16.last != 10 { result += "\n" }
                result += delimiter
                if index < spans.count { result += "\n" }
            } else {
                result += encodeList(group, style: block.style, inline: inline)
            }
            previousStyle = block.style
        }
        flush()
        return result
    }

    static func listMarker(_ text: String) -> (style: MessageEditorBlockStyle, display: String, body: String)? {
        guard let match = text.range(of: #"^(?:[-+*] |[0-9]{1,9}[.)] )"#, options: .regularExpression) else { return nil }
        let prefix = String(text[match])
        let numbered = prefix.first?.isNumber == true
        let number = prefix.prefix(while: \.isNumber)
        return (numbered ? .numberedList : .bulletList, numbered ? number + ". " : "• ", String(text[match.upperBound...]))
    }

    static func quoteMarker(_ text: String) -> (style: MessageEditorBlockStyle, display: String, body: String)? {
        guard text.hasPrefix(">"), text.count == 1 || text.dropFirst().first == " " || text.dropFirst().first == "\n" else { return nil }
        return (.quote, "> ", String(text.dropFirst(text.hasPrefix("> ") ? 2 : 1)))
    }

    static func canInterruptParagraph(style: MessageEditorBlockStyle, line: String, body: String) -> Bool {
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (style != .numberedList || Int(line.prefix(while: \.isNumber)) == 1)
    }

    static func displayPrefixLength(_ text: String, style: MessageEditorBlockStyle) -> Int {
        let pattern = style == .quote ? #"^> "# : style == .bulletList ? #"^• "# : #"^[0-9]{1,9}\. "#
        return text.range(of: pattern, options: .regularExpression).map { NSRange($0, in: text).length } ?? 0
    }

    private static func encodeList(_ spans: [MessageEditorSpan], style: MessageEditorBlockStyle,
                                   inline: ([MessageEditorSpan]) -> String) -> String {
        var result = ""
        var line: [MessageEditorSpan] = []
        func flush() {
            guard !line.isEmpty else { return }
            let text = line.map(\.text).joined()
            let length = displayPrefixLength(text, style: style)
            let prefix = String(text.prefix(length))
            let marker = style == .bulletList ? "- " : prefix
            var remaining = length
            let body = line.compactMap { span -> MessageEditorSpan? in
                var copy = span
                let removed = min(remaining, copy.text.utf16.count)
                copy.text = (copy.text as NSString).substring(from: removed)
                copy.block = nil
                remaining -= removed
                return copy.text.isEmpty ? nil : copy
            }
            result += (length > 0 ? marker : "") + inline(body)
            line = []
        }
        for span in spans {
            for part in lines(span.text) {
                var copy = span
                copy.text = part
                line.append(copy)
                if part.utf16.last == 10 { flush() }
            }
        }
        flush()
        return result
    }

    private static func lines(_ source: String) -> [String] {
        guard !source.isEmpty else { return [] }
        let parts = source.components(separatedBy: "\n")
        return parts.enumerated().compactMap { index, part in
            if index == parts.count - 1 { return part.isEmpty ? nil : part }
            return part + "\n"
        }
    }

    private static func fence(_ line: String) -> (marker: Character, count: Int, info: String)? {
        let text = line.trimmingCharacters(in: .newlines)
        guard let marker = text.first, marker == "`" || marker == "~" else { return nil }
        let count = text.prefix(while: { $0 == marker }).count
        let info = String(text.dropFirst(count)).trimmingCharacters(in: .whitespaces)
        guard count >= 3, marker != "`" || !info.contains("`") else { return nil }
        return (marker, count, info)
    }

    private static func closesFence(_ line: String, opening: (marker: Character, count: Int, info: String)) -> Bool {
        let text = line.trimmingCharacters(in: .newlines)
        let indent = text.prefix(while: { $0 == " " }).count
        guard indent <= 3 else { return false }
        let content = text.dropFirst(indent)
        let count = content.prefix(while: { $0 == opening.marker }).count
        let suffix = content.dropFirst(count)
        return count >= opening.count && suffix.allSatisfy { $0 == " " || $0 == "\t" }
    }

    private static func append(_ spans: [MessageEditorSpan], to result: inout [MessageEditorSpan]) {
        for span in spans {
            if let last = result.last, last.style == span.style, last.link == span.link, last.block == span.block,
               last.reference == nil, span.reference == nil {
                result[result.count - 1].text += span.text
            } else {
                result.append(span)
            }
        }
    }
}
