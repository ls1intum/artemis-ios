import Foundation
import Observation
import UIKit

extension NSAttributedString.Key {
    static let messageStyle = NSAttributedString.Key("artemis.message.style")
}

/// The attributed display document is separate from the Markdown sent to the server.
/// Unsupported legacy syntax stays in an explicit source editor instead of being flattened.
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
    private(set) var isSourceFallback = false
    var selection = NSRange(location: 0, length: 0)
    var typingStyle: MessageEditorStyle = []
    @ObservationIgnored var applyEdit: ((NSAttributedString, NSRange) -> Void)?

    func load(_ source: String) {
        guard source != markdown || (source.isEmpty && isSourceFallback) else { return }
        markdown = source
        if let spans = MessageEditorCodec.decode(source) {
            isSourceFallback = false
            content = Self.attributed(spans)
        } else {
            isSourceFallback = true
            content = NSAttributedString(string: source, attributes: Self.attributes([]))
        }
        selection = NSRange(location: content.length, length: 0)
        typingStyle = []
    }

    func accept(_ value: NSAttributedString, selection: NSRange) {
        content = NSAttributedString(attributedString: value)
        self.selection = selection
        markdown = isSourceFallback ? value.string : MessageEditorCodec.encode(Self.spans(value))
    }

    func markdown(in range: NSRange) -> String {
        guard NSMaxRange(range) <= content.length else { return "" }
        let value = content.attributedSubstring(from: range)
        return isSourceFallback ? value.string : MessageEditorCodec.encode(Self.spans(value))
    }

    func plainText(in range: NSRange) -> String {
        guard NSMaxRange(range) <= content.length else { return "" }
        return Self.spans(content.attributedSubstring(from: range)).map { $0.reference?.label ?? $0.text }.joined()
    }

    var canSetLink: Bool {
        guard !isSourceFallback else { return false }
        var containsReference = false
        content.enumerateAttribute(.attachment, in: selection) { value, _, _ in
            if value != nil { containsReference = true }
        }
        return !containsReference
    }

    var completion: Completion? {
        guard selection.length == 0, selection.location <= content.length else { return nil }
        let prefix = (content.string as NSString).substring(to: selection.location)
        guard let match = prefix.range(of: #"(?:^|[\s(])([@#])([\p{L}\p{N}_-]*)$"#, options: .regularExpression) else { return nil }
        let candidate = prefix[match].drop(while: { $0 != "@" && $0 != "#" })
        guard let trigger = candidate.first else { return nil }
        let range = NSRange(location: selection.location - candidate.utf16.count, length: candidate.utf16.count)
        if !isSourceFallback, range.location < content.length {
            let attributes = content.attributes(at: range.location, effectiveRange: nil)
            if attributes[.attachment] != nil || attributes[.link] != nil || Self.style(attributes).contains(.code) { return nil }
        }
        return Completion(trigger: trigger, query: String(candidate.dropFirst()), range: range)
    }

    func toggle(_ style: MessageEditorStyle) {
        guard !isSourceFallback else { return }
        guard selection.length > 0 else {
            typingStyle.formSymmetricDifference(style)
            return
        }
        let value = NSMutableAttributedString(attributedString: content)
        let remove = activeStyle.contains(style)
        content.enumerateAttributes(in: selection) { attributes, range, _ in
            guard attributes[.attachment] == nil else { return }
            var combined = Self.style(attributes)
            if remove { combined.subtract(style) } else { combined.formUnion(style) }
            value.addAttributes(Self.attributes(combined), range: range)
        }
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
        replace(selection, with: NSAttributedString(string: text, attributes: Self.attributes(typingStyle)))
    }

    /// Toolbar triggers establish a word boundary; ordinary typing still follows email rules.
    func beginCompletion(_ trigger: Character) {
        let before = (content.string as NSString).substring(to: selection.location)
        let prefix = before.last.map { $0.isWhitespace || $0 == "(" ? "" : " " } ?? ""
        insertText(prefix + String(trigger))
    }

    func insertMarkup(_ source: String, replacing range: NSRange? = nil) {
        let replacement: NSAttributedString
        if !isSourceFallback, let spans = MessageEditorCodec.decode(source) {
            replacement = Self.attributed(spans)
        } else {
            replacement = NSAttributedString(string: source, attributes: Self.attributes([]))
        }
        replace(range ?? selection, with: replacement)
    }

    func removeMarkup(_ source: String) {
        let value = NSMutableAttributedString(attributedString: content)
        if isSourceFallback {
            let text = content.string.replacingOccurrences(of: source, with: "")
            value.setAttributedString(NSAttributedString(string: text, attributes: Self.attributes([])))
        } else {
            var ranges: [NSRange] = []
            content.enumerateAttribute(.attachment, in: NSRange(location: 0, length: content.length)) { attachment, range, _ in
                if let attachment = attachment as? MessageReferenceAttachment, attachment.reference.markup == source {
                    ranges.append(range)
                }
            }
            for range in ranges.reversed() { value.deleteCharacters(in: range) }
        }
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
        guard canSetLink, MessageEditorLinkValidation.isValid(address) else { return }
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
        guard !isSourceFallback, proposed.length > 0, proposed.location < content.length else { return nil }
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

    private func replace(_ range: NSRange, with replacement: NSAttributedString) {
        guard range.location >= 0, NSMaxRange(range) <= content.length else { return }
        let value = NSMutableAttributedString(attributedString: content)
        value.replaceCharacters(in: range, with: replacement)
        commit(value, selection: NSRange(location: range.location + replacement.length, length: 0))
    }

    private func commit(_ value: NSAttributedString, selection: NSRange) {
        if let applyEdit { applyEdit(value, selection) } else { accept(value, selection: selection) }
    }

    static func attributes(_ style: MessageEditorStyle) -> [NSAttributedString.Key: Any] {
        var traits: UIFontDescriptor.SymbolicTraits = []
        if style.contains(.bold) { traits.insert(.traitBold) }
        if style.contains(.italic) { traits.insert(.traitItalic) }
        let base = UIFont.preferredFont(forTextStyle: .body)
        let font = style.contains(.code) ? UIFont.monospacedSystemFont(ofSize: base.pointSize, weight: style.contains(.bold) ? .bold : .regular) :
            UIFont(descriptor: base.fontDescriptor.withSymbolicTraits(traits) ?? base.fontDescriptor, size: 0)
        return [.font: font, .foregroundColor: UIColor.label, .messageStyle: style.rawValue,
                .underlineStyle: style.contains(.underline) ? NSUnderlineStyle.single.rawValue : 0,
                .strikethroughStyle: style.contains(.strikethrough) ? NSUnderlineStyle.single.rawValue : 0]
    }

    static func style(_ attributes: [NSAttributedString.Key: Any]) -> MessageEditorStyle {
        MessageEditorStyle(rawValue: attributes[.messageStyle] as? Int ?? 0)
    }

    private static func attributed(_ spans: [MessageEditorSpan]) -> NSAttributedString {
        let value = NSMutableAttributedString(string: "")
        for span in spans {
            if let reference = span.reference {
                value.append(NSAttributedString(attachment: MessageReferenceAttachment(reference: reference)))
            } else {
                var attributes = attributes(span.style)
                if let link = span.link { attributes[.link] = link }
                value.append(NSAttributedString(string: span.text, attributes: attributes))
            }
        }
        return value
    }

    private static func spans(_ value: NSAttributedString) -> [MessageEditorSpan] {
        var spans: [MessageEditorSpan] = []
        value.enumerateAttributes(in: NSRange(location: 0, length: value.length)) { attributes, range, _ in
            if let attachment = attributes[.attachment] as? MessageReferenceAttachment {
                spans.append(MessageEditorSpan(text: "\u{fffc}", reference: attachment.reference))
            } else {
                spans.append(MessageEditorSpan(text: (value.string as NSString).substring(with: range), style: style(attributes),
                                               link: attributes[.link].map { String(describing: $0) }))
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
