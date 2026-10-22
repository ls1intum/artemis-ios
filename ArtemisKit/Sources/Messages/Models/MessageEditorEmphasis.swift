import Foundation

/// CommonMark delimiter flanking depends on neighboring runs. Keep alternate closing
/// delimiter states until the following run proves which representation is valid.
enum MessageEditorEmphasis {
    static func encode(_ spans: [MessageEditorSpan], body: ([MessageEditorSpan]) -> String) -> String? {
        let marks: MessageEditorStyle = [.bold, .italic]
        var groups: [[MessageEditorSpan]] = []
        for span in spans {
            if let previous = groups.last?.first, previous.style.intersection(marks) == span.style.intersection(marks) {
                groups[groups.count - 1].append(span)
            } else {
                groups.append([span])
            }
        }
        if groups.count == 1, let group = groups.first, let first = group.first {
            if first.style.isDisjoint(with: marks) { return body(group) }
            let candidate = variants(body(group), style: first.style)[0]
            if matches(candidate, spans: group) { return candidate }
        }
        var states = [""]
        var expected: [MessageEditorSpan] = []
        for group in groups {
            expected += group
            var next: [String: String] = [:]
            var order: [String] = []
            for prefix in states {
                for option in variants(body(group), style: group[0].style) {
                    let candidate = prefix + option
                    guard matches(candidate, spans: expected) else { continue }
                    let tail = String(candidate.reversed().prefix { $0 == "*" || $0 == "_" }.reversed())
                    if next[tail] == nil { next[tail] = candidate; order.append(tail) }
                }
            }
            guard !next.isEmpty else { return nil }
            states = order.compactMap { next[$0] }
        }
        return states.first
    }

    private static func variants(_ text: String, style: MessageEditorStyle) -> [String] {
        let delimiters: [(String, String)]
        switch (style.contains(.bold), style.contains(.italic)) {
        case (true, true): delimiters = [("***", "***"), ("___", "___"), ("**_", "_**"), ("__*", "*__"), ("*__", "__*"), ("_**", "**_")]
        case (true, false): delimiters = [("**", "**"), ("__", "__")]
        case (false, true): delimiters = [("*", "*"), ("_", "_")]
        case (false, false): return [text]
        }
        return delimiters.map { opening, closing in
            text.components(separatedBy: "\n").map { line in
                guard let first = line.firstIndex(where: { !$0.isWhitespace }), let last = line.lastIndex(where: { !$0.isWhitespace }) else { return line }
                let end = line.index(after: last)
                return String(line[..<first]) + opening + line[first..<end] + closing + line[end...]
            }.joined(separator: "\n")
        }
    }

    private static func matches(_ source: String, spans: [MessageEditorSpan]) -> Bool {
        guard let value = try? AttributedString(markdown: source, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) else { return false }
        var actual: [Unit] = []
        for run in value.runs {
            let text = String(value[run.range].characters)
            let intent = run.inlinePresentationIntent ?? []
            if intent.contains(.inlineHTML), text == "<ins>" || text == "</ins>" { continue }
            let marks = (intent.contains(.stronglyEmphasized) ? 1 : 0) + (intent.contains(.emphasized) ? 2 : 0)
            actual += text.map { Unit(character: $0, marks: $0.isWhitespace ? 0 : marks) }
        }
        let expected = spans.flatMap { span in
            let marks = (span.style.contains(.bold) ? 1 : 0) + (span.style.contains(.italic) ? 2 : 0)
            return span.text.map { Unit(character: $0, marks: $0.isWhitespace ? 0 : marks) }
        }
        return actual == expected
    }

    private struct Unit: Equatable {
        let character: Character
        let marks: Int
    }
}
