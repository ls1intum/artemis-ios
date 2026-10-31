import Foundation

/// Foundation supplies the CommonMark emphasis rules, including adjacent and crossing runs.
/// The scanner still validates links and protects custom references before parsing.
enum MessageEditorCommonMark {
    static func decode(_ source: String) -> [MessageEditorSpan]? {
        var scanner = MessageEditorInlineParser(source)
        guard let (protected, references) = try? scanner.protectedSource(),
              let value = try? AttributedString(markdown: protected, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) else { return nil }
        var spans: [MessageEditorSpan] = []
        var underline = 0
        var emphasisFound = false
        var literalStars = 0
        for run in value.runs {
            let text = String(value[run.range].characters)
            let intent = run.inlinePresentationIntent ?? []
            if intent.contains(.inlineHTML) {
                if text == "<ins>" { underline += 1 } else if text == "</ins>", underline > 0 { underline -= 1 } else { return nil }
                continue
            }
            let style = style(for: intent, underlined: underline > 0)
            emphasisFound = emphasisFound || !style.isDisjoint(with: [.bold, .italic])
            if let link = run.link, !MessageEditorLinkValidation.isValid(link.absoluteString) { return nil }
            if !style.contains(.code) { literalStars += text.filter { $0 == "*" }.count }
            for character in text {
                if let first = character.unicodeScalars.first, let payload = references[Character(first)] {
                    for var span in payload {
                        span.style.formUnion(style)
                        emphasisFound = emphasisFound || !span.style.isDisjoint(with: [.bold, .italic])
                        append(span, to: &spans)
                    }
                    var tail = String(character)
                    tail.unicodeScalars.removeFirst()
                    if !tail.isEmpty {
                        append(MessageEditorSpan(text: tail, style: style, link: run.link?.absoluteString), to: &spans)
                    }
                } else {
                    append(MessageEditorSpan(text: String(character), style: style, link: run.link?.absoluteString), to: &spans)
                }
            }
        }
        let escapedStars = source.ranges(of: "\\*").count
        guard emphasisFound, underline == 0, literalStars <= escapedStars else { return nil }
        return spans
    }
    private static func append(_ span: MessageEditorSpan, to spans: inout [MessageEditorSpan]) {
        if let previous = spans.last, previous.style == span.style, previous.link == span.link, previous.reference == nil, span.reference == nil {
            spans[spans.count - 1].text += span.text
        } else {
            spans.append(span)
        }
    }

    private static func style(for intent: InlinePresentationIntent, underlined: Bool) -> MessageEditorStyle {
        var style: MessageEditorStyle = []
        if intent.contains(.stronglyEmphasized) { style.insert(.bold) }
        if intent.contains(.emphasized) { style.insert(.italic) }
        if intent.contains(.strikethrough) { style.insert(.strikethrough) }
        if intent.contains(.code) { style.insert(.code) }
        if underlined { style.insert(.underline) }
        return style
    }
}
