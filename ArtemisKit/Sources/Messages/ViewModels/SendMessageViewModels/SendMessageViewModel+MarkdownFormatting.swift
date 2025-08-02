//
//  SendMessageViewModel+MarkdownFormatting.swift.swift
//  ArtemisKit
//
//  Created by Eylul Naz Can on 28.02.2025.
//

import Foundation
import SharedModels
import SwiftUI

extension SendMessageViewModel {

    // MARK: List formatting
    func handleListFormatting(_ newValue: String) {
        let modifiedText = SendMessageListUtil.handleTextChange(newValue, text: text)
        if modifiedText != text {
            text = modifiedText
            moveCursorToEnd()
        }
    }

    /// Inserts the list prefix using our utility and updates the text.
    func insertListPrefix(unordered: Bool) {
        text = SendMessageListUtil.insertListPrefix(text: text, unordered: unordered)
        moveCursorToEnd()
    }

    // MARK: Text formatting

    func didTapBoldButton() {
        appendToSelection(before: "**", after: "**", placeholder: "bold")
    }

    func didTapItalicButton() {
        appendToSelection(before: "*", after: "*", placeholder: "italic")
    }

    func didTapUnderlineButton() {
        appendToSelection(before: "<ins>", after: "</ins>", placeholder: "underlined")
    }

    func didTapStrikethroughButton() {
        appendToSelection(before: "~~", after: "~~", placeholder: "strikethough")
    }

    func didTapBlockquoteButton() {
        appendToSelection(before: "> ", after: "", placeholder: "Reference")
    }

    func didTapCodeButton() {
        appendToSelection(before: "`", after: "`", placeholder: "Code")
    }

    func didTapCodeBlockButton() {
        appendToSelection(before: "```java\n", after: "\n```", placeholder: "Source Code")
    }

    func didTapLinkButton() {
        appendToSelection(before: "[", after: "](https://)", placeholder: "Display Text")
    }

    // MARK: - Content mentions

    func didTapAtButton() {
        if conditionalPresentation == .memberPicker {
            isMemberPickerSuppressed = true
        } else {
            isMemberPickerSuppressed = false
            appendToSelection(before: "@", after: " ", placeholder: " ")
        }
    }

    func didTapNumberButton() {
        if conditionalPresentation == .channelPicker {
            isChannelPickerSuppressed = true
        } else {
            isChannelPickerSuppressed = false
            appendToSelection(before: "#", after: " ", placeholder: " ")
        }
    }

    func searchChannel() -> Substring? {
        return text.matches(of: #/#(?<candidate>[\w-]*)/#).last?.candidate
    }

    func replace(channel: ChannelIdAndNameDTO) {
        guard let candidate = searchChannel() else {
            return
        }
        let channelMention = "[channel]\(channel.name)(\(channel.id))[/channel]"
        text = text.replacingOccurrences(of: "#" + candidate, with: channelMention)
        moveCursor(after: channelMention)
    }

    func searchMember() -> Substring? {
        let matches = text.matches(of: #/@(?<candidate>[\w]*\s?)/#)
        let candidate = matches.last?.candidate
        if candidate == " " || candidate?.contains(".") == true {
            // Either space after @ or a period indicating an email address -> Hide the member picker
            return nil
        }
        return candidate?.filter { $0 != Character(" ") }
    }

    func replace(member: UserNameAndLoginDTO) {
        guard let candidate = searchMember(),
              let name = member.name, let login = member.login else {
            return
        }
        let userMention = "[user]\(name)(\(login))[/user]"
        text = text.replacingOccurrences(of: "@" + candidate, with: userMention)
        moveCursor(after: userMention)
    }

    // MARK: File uploads

    func insertImageMention(path: String) {
        appendToSelection(before: "![", after: "](\(path))", placeholder: "image")
    }

    func insertFileMention(path: String, fileName: String) {
        appendToSelection(before: "[", after: "](\(path))", placeholder: fileName)
    }

    // MARK: Cursor/Selection management

    func moveCursorToEnd() {
        _selection = TextSelection(insertionPoint: text.endIndex)
    }

    func makeInsertion(insertionPoint: String.Index) {
        _selection = TextSelection(insertionPoint: insertionPoint)
    }

    private func moveCursor(after string: String) {
        if let range = text.range(of: string) {
            _selection = TextSelection(insertionPoint: range.upperBound)
        }
    }

    /// Prepends/Appends the given snippets to text the user has selected.
    private func appendToSelection(before: String, after: String, placeholder: String) {
        let placeholderText = "\(before)\(placeholder)\(after)"
        var shouldSelectPlaceholder = false

        if let selection = _selection {
            switch selection.indices {
            case .selection(let range):
                let newText: String
                if text[range].isEmpty {
                    newText = placeholderText
                    shouldSelectPlaceholder = true
                } else {
                    newText = "\(before)\(text[range])\(after)"
                }
                text.replaceSubrange(range, with: newText)
                if !shouldSelectPlaceholder {
                    moveCursor(after: newText)
                }
            default:
                break
            }
        } else {
            text.append(placeholderText)
            shouldSelectPlaceholder = true
        }

        if shouldSelectPlaceholder {
            for range in text.ranges(of: placeholderText) {
                if let placeholderRange = text[range].range(of: placeholder) {
                    _selection = TextSelection(range: range.clamped(to: placeholderRange))
                }
            }
        }
    }
}
