import Foundation
import UIKit

extension MessageEditorDocument {
    var activeBlockStyle: MessageEditorBlockStyle? {
        selectedBlock?.style
    }

    var canFormatInline: Bool {
        selection.length == 0 ? activeBlockStyle != .codeBlock : !containsCode(in: selection)
    }

    var typingAttributes: [NSAttributedString.Key: Any] {
        var attributes = Self.attributes(activeBlockStyle == .codeBlock ? .code : typingStyle)
        if let block = selectedBlock { attributes.merge(Self.blockAttributes(block)) { _, value in value } }
        return attributes
    }

    /// Paragraph transforms flow through the same native edit/undo hook as inline formatting.
    func toggleBlock(_ style: MessageEditorBlockStyle) {
        guard !hasUnsupportedContent else { return }
        let range = style == .codeBlock && activeBlockStyle == .codeBlock ? selectedCodeBlockRange : selectedParagraphs
        let value = NSMutableAttributedString(attributedString: content)
        if style == .codeBlock {
            toggleCodeBlock(in: value, range: range)
        } else {
            toggleList(style, in: value, range: range)
        }
    }

    /// Returns true only when the editor consumed an edit. IME composition is left to UITextView.
    func handleReplacement(in range: NSRange, text: String) -> Bool {
        guard !hasUnsupportedContent, range.location >= 0, NSMaxRange(range) <= content.length else { return false }
        if activeBlockStyle == .codeBlock { return handleCodeReplacement(in: range, text: text) }
        let paragraph = (content.string as NSString).paragraphRange(for: NSRange(location: range.location, length: 0))
        let line = (content.string as NSString).substring(with: paragraph)
        if let block = selectedBlock, block.style != .codeBlock {
            return handleListReplacement(in: range, text: text, paragraph: paragraph, line: line, block: block)
        }
        guard range.length == 0, text == " " else { return false }
        let offset = range.location - paragraph.location
        let prefix = (line as NSString).substring(to: offset)
        let suffix = (line as NSString).substring(from: offset)
        guard suffix.allSatisfy(\.isNewline),
              let marker = MessageEditorBlockCodec.listMarker(prefix + text), marker.body.isEmpty else { return false }
        let block = MessageEditorBlock(style: marker.style)
        let attributes = Self.attributes(typingStyle).merging(Self.blockAttributes(block)) { _, value in value }
        let value = NSMutableAttributedString(attributedString: content)
        value.replaceCharacters(in: paragraph, with: NSAttributedString(string: marker.display + suffix, attributes: attributes))
        var selection = NSRange(location: paragraph.location + marker.display.utf16.count, length: 0)
        normalizeListParagraphBoundaries(in: value, selection: &selection)
        commit(value, selection: selection)
        return true
    }

    static func blockAttributes(_ block: MessageEditorBlock) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [.messageBlock: block.style.rawValue]
        if block.style == .codeBlock {
            attributes[.messageCodeLanguage] = block.language
            attributes[.messageCodeIdentifier] = block.identifier
            attributes[.messageCodeEmpty] = block.isEmpty
            attributes[.backgroundColor] = UIColor.secondarySystemFill
        }
        return attributes
    }

    static func block(_ attributes: [NSAttributedString.Key: Any]) -> MessageEditorBlock? {
        guard let raw = attributes[.messageBlock] as? String, let style = MessageEditorBlockStyle(rawValue: raw) else { return nil }
        return MessageEditorBlock(style: style, language: attributes[.messageCodeLanguage] as? String ?? "",
                                  identifier: attributes[.messageCodeIdentifier] as? Int ?? 0, isEmpty: attributes[.messageCodeEmpty] as? Bool ?? false)
    }

    func block(at location: Int) -> MessageEditorBlock? {
        guard content.length > 0, location <= content.length else { return nil }
        let index = min(location, content.length - 1)
        let block = Self.block(content.attributes(at: index, effectiveRange: nil))
        if location == content.length, content.string.utf16.last == 10, block?.style != .codeBlock { return nil }
        return block
    }

    func markupReplacement(_ spans: [MessageEditorSpan], in range: NSRange) -> NSAttributedString {
        let maximum = Self.spans(content).compactMap { $0.block?.identifier }.max() ?? 0
        let adjusted = spans.map { span in
            var copy = span
            if copy.block?.style == .codeBlock { copy.block?.identifier += maximum }
            return copy
        }
        let replacement = NSMutableAttributedString(attributedString: Self.attributed(adjusted))
        if spans.contains(where: { $0.block != nil }) {
            let text = content.string as NSString
            if range.location > 0, text.character(at: range.location - 1) != 10 {
                replacement.insert(NSAttributedString(string: "\n", attributes: Self.attributes([])), at: 0)
            }
            if NSMaxRange(range) < content.length, text.character(at: NSMaxRange(range)) != 10 {
                let isList = spans.last?.block?.style != .codeBlock
                let suffix = replacement.string.utf16.last == 10 ? (isList ? "\n" : "") : (isList ? "\n\n" : "\n")
                replacement.append(NSAttributedString(string: suffix, attributes: Self.attributes([])))
            }
        } else if let block = block(at: range.location) {
            replacement.addAttributes(Self.blockAttributes(block), range: NSRange(location: 0, length: replacement.length))
        }
        return replacement
    }

    private var selectedBlock: MessageEditorBlock? {
        let block = block(at: selection.location)
        if selection.length == 0 { return block }
        var common = block
        content.enumerateAttributes(in: selection) { attributes, _, stop in
            if Self.block(attributes)?.style != common?.style {
                common = nil
                stop.pointee = true
            }
        }
        return common
    }

    private var selectedCodeBlockRange: NSRange {
        var result = selectedParagraphs
        let selected = selectedBlock
        content.enumerateAttributes(in: NSRange(location: 0, length: content.length)) { attributes, range, _ in
            if Self.block(attributes) == selected { result = NSUnionRange(result, range) }
        }
        return result
    }

    private var selectedParagraphs: NSRange {
        let text = content.string as NSString
        var range = selection
        // A selection ending at the start of the next paragraph does not include that paragraph.
        if range.length > 0, NSMaxRange(range) > 0,
           text.substring(with: NSRange(location: NSMaxRange(range) - 1, length: 1)) == "\n" { range.length -= 1 }
        return text.paragraphRange(for: range)
    }

    private func toggleList(_ style: MessageEditorBlockStyle, in value: NSMutableAttributedString, range: NSRange) {
        guard !containsCode(in: range) else { return }
        let remove = activeBlockStyle == style
        var paragraphs: [NSRange] = []
        var position = range.location
        repeat {
            let paragraph = (content.string as NSString).paragraphRange(for: NSRange(location: position, length: 0))
            paragraphs.append(paragraph)
            position = NSMaxRange(paragraph)
        } while position < NSMaxRange(range)
        var newSelection = selection
        for (offset, paragraph) in paragraphs.enumerated().reversed() {
            let line = (content.string as NSString).substring(with: paragraph)
            let oldBlock = paragraph.length > 0 ? Self.block(content.attributes(at: paragraph.location, effectiveRange: nil)) : nil
            let removed = oldBlock.map { MessageEditorBlockCodec.displayPrefixLength(line, style: $0.style) } ?? 0
            let prefix = remove ? "" : style == .bulletList ? "• " : "\(offset + 1). "
            let body = NSRange(location: paragraph.location + removed, length: paragraph.length - removed)
            let replacement = NSMutableAttributedString(attributedString: content.attributedSubstring(from: body))
            clearBlock(in: replacement, range: NSRange(location: 0, length: replacement.length))
            if !remove {
                let attributes = Self.attributes([]).merging(Self.blockAttributes(MessageEditorBlock(style: style))) { _, value in value }
                replacement.insert(NSAttributedString(string: prefix, attributes: attributes), at: 0)
                replacement.addAttributes(Self.blockAttributes(MessageEditorBlock(style: style)), range: NSRange(location: 0, length: replacement.length))
            }
            value.replaceCharacters(in: paragraph, with: replacement)
            newSelection = adjustedSelection(newSelection, at: paragraph.location, removed: removed, inserted: prefix.utf16.count)
        }
        normalizeListParagraphBoundaries(in: value, selection: &newSelection)
        commit(value, selection: newSelection)
    }

    private func normalizeListParagraphBoundaries(in value: NSMutableAttributedString, selection: inout NSRange) {
        let text = value.string as NSString
        var boundaries: [Int] = []
        var position = 0
        while position < value.length {
            let paragraph = text.paragraphRange(for: NSRange(location: position, length: 0))
            let next = NSMaxRange(paragraph)
            if next < value.length, let block = Self.block(value.attributes(at: position, effectiveRange: nil)),
               block.style != .codeBlock, Self.block(value.attributes(at: next, effectiveRange: nil)) == nil,
               !text.substring(with: text.paragraphRange(for: NSRange(location: next, length: 0))).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                boundaries.append(next)
            }
            if next < value.length, Self.block(value.attributes(at: position, effectiveRange: nil)) == nil,
               !text.substring(with: paragraph).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let block = Self.block(value.attributes(at: next, effectiveRange: nil)), block.style != .codeBlock {
                let line = text.substring(with: text.paragraphRange(for: NSRange(location: next, length: 0)))
                let length = MessageEditorBlockCodec.displayPrefixLength(line, style: block.style)
                let body = (line as NSString).substring(from: length)
                if !MessageEditorBlockCodec.canInterruptParagraph(style: block.style, line: line, body: body) { boundaries.append(next) }
            }
            position = next
        }
        for boundary in boundaries.reversed() {
            value.insert(NSAttributedString(string: "\n", attributes: Self.attributes([])), at: boundary)
            selection = adjustedSelection(selection, at: boundary, removed: 0, inserted: 1)
        }
    }

    private func toggleCodeBlock(in value: NSMutableAttributedString, range: NSRange) {
        let remove = activeBlockStyle == .codeBlock
        let replacement = NSMutableAttributedString(attributedString: content.attributedSubstring(from: range))
        var containsAttachment = false
        replacement.enumerateAttribute(.attachment, in: NSRange(location: 0, length: replacement.length)) { attachment, _, _ in
            if attachment != nil { containsAttachment = true }
        }
        guard !containsAttachment else { return }
        if remove {
            clearBlock(in: replacement, range: NSRange(location: 0, length: replacement.length))
            replacement.setAttributes(Self.attributes([]), range: NSRange(location: 0, length: replacement.length))
        } else {
            guard !hasList(in: range) else { return }
            if replacement.string.utf16.last != 10 { replacement.append(NSAttributedString(string: "\n")) }
            let identifier = Self.spans(content).compactMap { $0.block?.identifier }.max() ?? 0
            let attributes = Self.attributes(.code).merging(Self.blockAttributes(MessageEditorBlock(style: .codeBlock, identifier: identifier + 1))) { _, value in value }
            replacement.setAttributes(attributes, range: NSRange(location: 0, length: replacement.length))
        }
        value.replaceCharacters(in: range, with: replacement)
        typingStyle = []
        let newSelection = selection.length > 0 ? NSRange(location: range.location, length: replacement.length) : selection
        commit(value, selection: newSelection)
    }

    private func handleCodeReplacement(in range: NSRange, text: String) -> Bool {
        guard text == "\n", range.length == 0 else { return false }
        let paragraph = (content.string as NSString).paragraphRange(for: range)
        let line = (content.string as NSString).substring(with: paragraph)
        let blockRange = selectedCodeBlockRange
        guard line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              NSMaxRange(paragraph) >= NSMaxRange(blockRange) else { return false }
        let value = NSMutableAttributedString(attributedString: content)
        let plain = NSAttributedString(string: "\n", attributes: Self.attributes([]))
        let caret: Int
        if paragraph.location == blockRange.location {
            // An empty code block still needs its attributed paragraph to preserve the fence.
            value.insert(plain, at: NSMaxRange(blockRange))
            caret = NSMaxRange(blockRange) + plain.length
        } else {
            value.replaceCharacters(in: paragraph, with: plain)
            caret = paragraph.location + plain.length
        }
        typingStyle = []
        commit(value, selection: NSRange(location: caret, length: 0))
        return true
    }

    private func handleListReplacement(in range: NSRange, text: String, paragraph: NSRange, line: String, block: MessageEditorBlock) -> Bool {
        let prefixLength = MessageEditorBlockCodec.displayPrefixLength(line, style: block.style)
        guard prefixLength > 0 else { return false }
        let bodyStart = paragraph.location + prefixLength
        if text.isEmpty, range.length == 1, selection.length == 0, selection.location == bodyStart {
            removeListMarker(in: paragraph, length: prefixLength)
            return true
        }
        guard text == "\n", range.location >= bodyStart else { return false }
        let body = (line as NSString).substring(from: prefixLength)
        if body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let ending = body.reversed().prefix(while: \.isNewline).reduce(0) { $0 + String($1).utf16.count }
            removeListMarker(in: paragraph, length: paragraph.length - ending)
        } else {
            let number = Int(line.prefix(while: \.isNumber)) ?? 0
            let prefix = block.style == .bulletList ? "• " : "\(number + 1). "
            let attributes = Self.attributes(typingStyle).merging(Self.blockAttributes(block)) { _, value in value }
            replace(range, with: NSAttributedString(string: "\n" + prefix, attributes: attributes))
        }
        return true
    }

    private func removeListMarker(in paragraph: NSRange, length: Int) {
        let value = NSMutableAttributedString(attributedString: content)
        value.deleteCharacters(in: NSRange(location: paragraph.location, length: length))
        clearBlock(in: value, range: NSRange(location: paragraph.location, length: paragraph.length - length))
        var caret = paragraph.location
        if caret > 0, let previous = Self.block(value.attributes(at: caret - 1, effectiveRange: nil)), previous.style != .codeBlock {
            value.insert(NSAttributedString(string: "\n", attributes: Self.attributes([])), at: caret)
            caret += 1
        }
        commit(value, selection: NSRange(location: caret, length: 0))
    }

    private func clearBlock(in value: NSMutableAttributedString, range: NSRange) {
        for key: NSAttributedString.Key in [.messageBlock, .messageCodeLanguage, .messageCodeIdentifier, .messageCodeEmpty, .backgroundColor] { value.removeAttribute(key, range: range) }
    }

    private func containsCode(in range: NSRange) -> Bool {
        var found = false
        content.enumerateAttributes(in: range) { attributes, _, _ in
            if Self.block(attributes)?.style == .codeBlock { found = true }
        }
        return found
    }

    private func hasList(in range: NSRange) -> Bool {
        var found = false
        content.enumerateAttributes(in: range) { attributes, _, _ in
            if let block = Self.block(attributes), block.style != .codeBlock { found = true }
        }
        return found
    }

    private func adjustedSelection(_ selection: NSRange, at location: Int, removed: Int, inserted: Int) -> NSRange {
        func adjusted(_ point: Int) -> Int {
            point < location ? point : max(location + inserted, point + inserted - removed)
        }
        let start = adjusted(selection.location)
        return NSRange(location: start, length: adjusted(NSMaxRange(selection)) - start)
    }
}
