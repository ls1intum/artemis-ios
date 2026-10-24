import Foundation
import Observation
import UIKit

extension NSAttributedString.Key {
    static let messageStyle = NSAttributedString.Key("artemis.message.style")
    static let messageBlock = NSAttributedString.Key("artemis.message.block")
    static let messageCodeLanguage = NSAttributedString.Key("artemis.message.code.language")
    static let messageCodeIdentifier = NSAttributedString.Key("artemis.message.code.identifier")
    static let messageCodeEmpty = NSAttributedString.Key("artemis.message.code.empty")
}

/// The attributed display document is separate from the Markdown sent to the server.
/// Unsupported content keeps its original payload and cannot be edited or sent.
@MainActor
@Observable
final class MessageEditorDocument {
    struct Completion: Hashable {
        let trigger: Character
        let query: String
        let range: NSRange
    }

    private(set) var content = NSAttributedString(string: "")
    private(set) var markdown = ""
    private(set) var hasUnsupportedContent = false
    var selection = NSRange(location: 0, length: 0)
    var typingStyle: MessageEditorStyle = []
    @ObservationIgnored var applyTypingAttributes: (() -> Void)?
    @ObservationIgnored var applyEdit: ((NSAttributedString, NSRange) -> Void)?
    @ObservationIgnored var onContentChange: (() -> Void)?

    func load(_ source: String) {
        guard source != markdown else { return }
        markdown = source
        if let spans = MessageEditorCodec.decode(source) {
            hasUnsupportedContent = false
            content = Self.attributed(spans)
        } else {
            hasUnsupportedContent = true
            content = NSAttributedString(string: "")
        }
        selection = NSRange(location: content.length, length: 0)
        if content.length == 1, Self.block(content.attributes(at: 0, effectiveRange: nil))?.isEmpty == true {
            selection = NSRange(location: 0, length: 0)
        }
        typingStyle = []
        onContentChange?()
    }

    func accept(_ value: NSAttributedString, selection: NSRange) {
        guard !hasUnsupportedContent else { return }
        // Native typing and autocorrection can replace custom attributes on an item body.
        // Its surviving paragraph start owns the block style, including at the end caret.
        let normalized = NSMutableAttributedString(attributedString: value)
        normalizeJoinedParagraphs(in: normalized, around: selection)
        content = NSAttributedString(attributedString: normalized)
        self.selection = selection
        markdown = MessageEditorCodec.encode(Self.spans(content))
        onContentChange?()
    }

    func markdown(in range: NSRange) -> String {
        guard !hasUnsupportedContent, range.location >= 0, NSMaxRange(range) <= content.length else { return "" }
        let value = content.attributedSubstring(from: range)
        return MessageEditorCodec.encode(Self.spans(value))
    }

    func plainText(in range: NSRange) -> String {
        guard NSMaxRange(range) <= content.length else { return "" }
        return Self.spans(content.attributedSubstring(from: range)).map { span in
            if let reference = span.reference { return reference.label }
            guard span.block?.style == .quote else { return span.text }
            let prefix = MessageEditorBlockCodec.quoteDisplayPrefix
            let text = span.text.replacingOccurrences(of: "\n" + prefix, with: "\n")
            return text.hasPrefix(prefix) ? String(text.dropFirst(prefix.count)) : text
        }.joined()
    }

    /// Formatting markers alone do not make a message sendable; atomic references do.
    var hasMessageBody: Bool {
        let text = content.string as NSString
        var position = 0
        while position < content.length {
            let paragraph = text.paragraphRange(for: NSRange(location: position, length: 0))
            let line = text.substring(with: paragraph)
            let block = Self.block(content.attributes(at: position, effectiveRange: nil))
            let prefix = block.map { $0.style == .codeBlock ? 0 : MessageEditorBlockCodec.displayPrefixLength(line, style: $0.style) } ?? 0
            if !(line as NSString).substring(from: prefix).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
            position = NSMaxRange(paragraph)
        }
        return false
    }

    var canSetLink: Bool {
        guard !hasUnsupportedContent, canFormatInline else { return false }
        let range = linkRange ?? selection
        guard (content.string as NSString).substring(with: range).rangeOfCharacter(from: .newlines) == nil else { return false }
        var containsReference = false
        content.enumerateAttribute(.attachment, in: selection) { value, _, _ in
            if value != nil { containsReference = true }
        }
        return !containsReference
    }

    var completion: Completion? {
        guard !hasUnsupportedContent, activeBlockStyle != .codeBlock, selection.length == 0, selection.location <= content.length else { return nil }
        let prefix = (content.string as NSString).substring(to: selection.location)
        guard let match = prefix.range(of: #"(?:^|[\s(\u200B])([@#])([\p{L}\p{N}_-]*)$"#, options: .regularExpression) else { return nil }
        let candidate = prefix[match].drop(while: { $0 != "@" && $0 != "#" })
        guard let trigger = candidate.first else { return nil }
        let range = NSRange(location: selection.location - candidate.utf16.count, length: candidate.utf16.count)
        if range.location < content.length {
            let attributes = content.attributes(at: range.location, effectiveRange: nil)
            if attributes[.attachment] != nil || attributes[.link] != nil || Self.style(attributes).contains(.code) { return nil }
        }
        return Completion(trigger: trigger, query: String(candidate.dropFirst()), range: range)
    }

    func toggle(_ style: MessageEditorStyle) {
        guard !hasUnsupportedContent, canFormatInline else { return }
        guard selection.length > 0 else {
            typingStyle.formSymmetricDifference(style)
            applyTypingAttributes?()
            return
        }
        let value = NSMutableAttributedString(attributedString: content)
        let remove = activeStyle.contains(style)
        var common: MessageEditorStyle?
        content.enumerateAttributes(in: selection) { attributes, range, _ in
            guard attributes[.attachment] == nil else { return }
            var combined = Self.style(attributes)
            if remove { combined.subtract(style) } else { combined.formUnion(style) }
            common = common.map { $0.intersection(combined) } ?? combined
            value.addAttributes(Self.attributes(combined), range: range)
        }
        typingStyle = common ?? []
        commit(value, selection: selection)
    }

    var activeStyle: MessageEditorStyle {
        guard content.length > 0 else { return typingStyle }
        if selection.length == 0 { return typingStyle }
        var common: MessageEditorStyle?
        content.enumerateAttributes(in: selection) { attributes, _, _ in
            let value = Self.style(attributes)
            common = common.map { $0.intersection(value) } ?? value
        }
        return common ?? []
    }

    func insertText(_ text: String) {
        replace(selection, with: NSAttributedString(string: text, attributes: typingAttributes))
    }

    /// Toolbar triggers establish a word boundary; ordinary typing still follows email rules.
    func beginCompletion(_ trigger: Character) {
        guard !hasUnsupportedContent else { return }
        let before = (content.string as NSString).substring(to: selection.location)
        let prefix = before.last.map { $0.isWhitespace || $0 == "(" || String($0) == MessageEditorBlockCodec.quoteDisplayPrefix ? "" : " " } ?? ""
        insertText(prefix + String(trigger))
    }

    func insertMarkup(_ source: String, replacing range: NSRange? = nil) {
        guard !hasUnsupportedContent else { return }
        var range = range ?? selection
        if activeBlockStyle == .codeBlock {
            replace(range, with: NSAttributedString(string: source, attributes: typingAttributes))
            return
        }
        let replacement: NSAttributedString
        if let spans = MessageEditorCodec.decode(source) {
            if !spans.contains(where: { $0.block != nil }) { range = inlineInsertionRange(range) }
            replacement = markupReplacement(spans, in: range)
        } else {
            range = inlineInsertionRange(range)
            replacement = markupReplacement([MessageEditorSpan(text: source, style: typingStyle)], in: range)
        }
        replace(range, with: replacement)
    }

    func removeMarkup(_ source: String) {
        guard !hasUnsupportedContent else { return }
        let value = NSMutableAttributedString(attributedString: content)
        var ranges: [NSRange] = []
        content.enumerateAttribute(.attachment, in: NSRange(location: 0, length: content.length)) { attachment, range, _ in
            if let attachment = attachment as? MessageReferenceAttachment, attachment.reference.markup == source {
                ranges.append(range)
            }
        }
        for range in ranges.reversed() { value.deleteCharacters(in: range) }
        commit(value, selection: NSRange(location: min(selection.location, value.length), length: 0))
    }

    var linkRange: NSRange? {
        guard content.length > 0 else { return nil }
        let index = min(selection.location, content.length - 1)
        var range = NSRange()
        guard content.attribute(.link, at: index, longestEffectiveRange: &range,
                                in: NSRange(location: 0, length: content.length)) != nil,
              selection.location >= range.location, NSMaxRange(selection) <= NSMaxRange(range) else { return nil }
        return range
    }

    var linkDetails: (label: String, address: String)? {
        guard let range = linkRange, let value = content.attribute(.link, at: range.location, effectiveRange: nil) else { return nil }
        return ((content.string as NSString).substring(with: range), String(describing: value))
    }

    func setLink(label: String, address: String) {
        guard canSetLink, label.rangeOfCharacter(from: .newlines) == nil, MessageEditorLinkValidation.isValid(address) else { return }
        let range = linkRange ?? selection
        let text = label.isEmpty ? address : label
        let existing = content.attributedSubstring(from: range)
        let replacement: NSMutableAttributedString
        if existing.string == text {
            replacement = NSMutableAttributedString(attributedString: existing)
        } else {
            var common: MessageEditorStyle?
            existing.enumerateAttributes(in: NSRange(location: 0, length: existing.length)) { attributes, _, _ in
                let style = Self.style(attributes)
                common = common.map { $0.intersection(style) } ?? style
            }
            replacement = NSMutableAttributedString(string: text, attributes: Self.attributes(common ?? typingStyle))
        }
        if let block = block(at: range.location) {
            replacement.addAttributes(Self.blockAttributes(block), range: NSRange(location: 0, length: replacement.length))
        }
        replacement.addAttribute(.link, value: address, range: NSRange(location: 0, length: replacement.length))
        let value = NSMutableAttributedString(attributedString: content)
        value.replaceCharacters(in: range, with: replacement)
        commit(value, selection: NSRange(location: range.location, length: replacement.length))
    }

    func unlink() {
        guard let range = linkRange else { return }
        let value = NSMutableAttributedString(attributedString: content)
        value.removeAttribute(.link, range: range)
        commit(value, selection: range)
    }

    /// Backspace at a reference/link first selects only that atom. A second deletion removes it.
    func atomicSelectionForDeletion(_ proposed: NSRange) -> NSRange? {
        guard !hasUnsupportedContent, proposed.length > 0, proposed.location < content.length else { return nil }
        var atom: NSRange?
        content.enumerateAttributes(in: proposed) { attributes, range, stop in
            if attributes[.attachment] != nil || attributes[.link] != nil {
                var effective = NSRange()
                let key: NSAttributedString.Key = attributes[.attachment] != nil ? .attachment : .link
                _ = content.attribute(key, at: range.location, longestEffectiveRange: &effective,
                                      in: NSRange(location: 0, length: content.length))
                atom = effective
                stop.pointee = true
            }
        }
        guard let atom else { return nil }
        if selection.length > 0, NSIntersectionRange(selection, atom) == atom { return nil }
        return atom
    }

    func replace(_ range: NSRange, with replacement: NSAttributedString) {
        guard !hasUnsupportedContent, range.location >= 0, NSMaxRange(range) <= content.length else { return }
        let value = NSMutableAttributedString(attributedString: content)
        value.replaceCharacters(in: range, with: replacement)
        normalizeJoinedParagraphs(in: value, around: NSRange(location: range.location, length: replacement.length))
        commit(value, selection: NSRange(location: range.location + replacement.length, length: 0))
    }

    func commit(_ value: NSAttributedString, selection: NSRange) {
        guard !hasUnsupportedContent else { return }
        let value = NSMutableAttributedString(attributedString: value)
        var selection = selection
        normalizeNumberedParagraphs(in: value, selection: &selection)
        if let applyEdit { applyEdit(value, selection) } else { accept(value, selection: selection) }
    }

    static func attributes(_ style: MessageEditorStyle) -> [NSAttributedString.Key: Any] {
        var traits: UIFontDescriptor.SymbolicTraits = []
        if style.contains(.bold) { traits.insert(.traitBold) }
        if style.contains(.italic) { traits.insert(.traitItalic) }
        let base = UIFont.preferredFont(forTextStyle: .body)
        let font = style.contains(.code) ? UIFont.monospacedSystemFont(ofSize: base.pointSize, weight: style.contains(.bold) ? .bold : .regular) :
            UIFont(descriptor: base.fontDescriptor.withSymbolicTraits(traits) ?? base.fontDescriptor, size: 0)
        return [.font: font, .foregroundColor: style.contains(.code) ? UIColor.systemRed : UIColor.label, .messageStyle: style.rawValue,
                .underlineStyle: style.contains(.underline) ? NSUnderlineStyle.single.rawValue : 0,
                .strikethroughStyle: style.contains(.strikethrough) ? NSUnderlineStyle.single.rawValue : 0]
    }

    static func style(_ attributes: [NSAttributedString.Key: Any]) -> MessageEditorStyle {
        MessageEditorStyle(rawValue: attributes[.messageStyle] as? Int ?? 0)
    }

    static func attributed(_ spans: [MessageEditorSpan]) -> NSAttributedString {
        let value = NSMutableAttributedString(string: "")
        for span in spans {
            if let reference = span.reference {
                let attachment = NSMutableAttributedString(attachment: MessageReferenceAttachment(reference: reference))
                attachment.addAttributes(attributes(span.style), range: NSRange(location: 0, length: attachment.length))
                if let block = span.block { attachment.addAttributes(blockAttributes(block), range: NSRange(location: 0, length: attachment.length)) }
                value.append(attachment)
            } else {
                var attributes = attributes(span.style)
                if let link = span.link { attributes[.link] = link }
                if let block = span.block { attributes.merge(blockAttributes(block)) { _, value in value } }
                value.append(NSAttributedString(string: span.text, attributes: attributes))
            }
        }
        return value
    }

    static func spans(_ value: NSAttributedString) -> [MessageEditorSpan] {
        var spans: [MessageEditorSpan] = []
        value.enumerateAttributes(in: NSRange(location: 0, length: value.length)) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? MessageReferenceAttachment {
                spans.append(MessageEditorSpan(text: "\u{fffc}", style: style(attributes), reference: attachment.reference, block: block(attributes)))
            } else {
                spans.append(MessageEditorSpan(text: (value.string as NSString).substring(with: range), style: style(attributes),
                                               link: attributes[.link].map { String(describing: $0) }, block: block(attributes)))
            }
        }
        return spans
    }
}

/// One text position keeps the complete reference indivisible while the payload stays server-compatible.
final class MessageReferenceAttachment: NSTextAttachment {
    let reference: MessageEditorReference

    init(reference: MessageEditorReference) {
        self.reference = reference
        super.init(data: nil, ofType: nil)
        let font = UIFont.preferredFont(forTextStyle: .body)
        let text = reference.label as NSString
        let width = min(270, text.size(withAttributes: [.font: font]).width + 16)
        let size = CGSize(width: width, height: font.lineHeight + 4)
        image = UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.secondarySystemFill.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 6).fill()
            text.draw(in: CGRect(x: 8, y: 2, width: width - 16, height: font.lineHeight),
                      withAttributes: [.font: font, .foregroundColor: UIColor.link])
        }
        bounds = CGRect(x: 0, y: font.descender - 2, width: width, height: size.height)
    }

    required init?(coder: NSCoder) { return nil }
}
