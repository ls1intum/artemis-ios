//
//  SendMessageListUtil.swift
//  ArtemisKit
//
//  Created by Eylul Naz Can on 25.02.2025.
//

import Foundation

struct SendMessageListUtil {

    enum BulletInfo {
        case unordered          // For lines starting with "- "
        case ordered(Int)       // For lines like "1. ", "2. ", etc.
    }

    /// Detects if `line` starts with either `- ` or `N. ` (where N is an integer).
    /// Returns `(BulletInfo, String)` if a bullet prefix is found,
    /// where the second value is the remaining text after the prefix.
    static func parseBulletPrefix(in line: String) -> (BulletInfo, String)? {
        let trimmed = line

        // 1) Unordered bullet check: "- "
        if trimmed.hasPrefix("- ") {
            let content = trimmed.dropFirst(2)
            return (.unordered, String(content))
        }

        // 2) Ordered bullet check via regex: e.g. "1. ", "12. ", etc.
        let pattern = #"^(\d+)\.\s(.*)$"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)),
            match.numberOfRanges == 3
        else {
            return nil
        }

        let numberRange = match.range(at: 1)
        let contentRange = match.range(at: 2)
        guard
            let swiftNumberRange = Range(numberRange, in: trimmed),
            let number = Int(trimmed[swiftNumberRange]),
            let swiftContentRange = Range(contentRange, in: trimmed)
        else {
            return nil
        }

        let content = trimmed[swiftContentRange]
        return (.ordered(number), String(content))
    }

    /// Inserts a new list item prefix based on the list type.
    static func insertListPrefix(text: String, unordered: Bool) -> String {
        var updatedText = text
        let prefix = unordered ? "- " : "1. "

        // If text is completely empty, start the list directly
        if updatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return prefix
        }

        // If text is not empty, ensure a newline before adding the list prefix
        if !updatedText.hasSuffix("\n") {
            updatedText.append("\n")
        }

        // Append the list prefix
        updatedText.append(prefix)
        return updatedText
    }

    /// Handles text changes when Enter is pressed to continue a list or remove empty bullets.
    static func handleTextChange(_ newValue: String, text: String) -> String {
        guard !newValue.isEmpty, newValue.hasSuffix("\n") else { return text}

        var lines = newValue.components(separatedBy: "\n")

        let previousLineIndex = lines.count - 2
        guard previousLineIndex >= 0 else { return text }

        let previousLine = lines[previousLineIndex]

        guard let (bulletInfo, contentAfterPrefix) = parseBulletPrefix(in: previousLine) else { return text}

        let trimmedContent = contentAfterPrefix.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedContent.isEmpty {
            // Remove empty bullet
            lines[previousLineIndex] = ""
        } else {
            // Continue list
            let newMarker: String
            switch bulletInfo {
            case .unordered:
                newMarker = "- "
            case .ordered(let number):
                newMarker = "\(number + 1). "
            }

            if let lastLine = lines.last, lastLine.isEmpty {
                lines[lines.count - 1] = newMarker
            } else {
                lines.append(newMarker)
            }
        }
        return lines.joined(separator: "\n")
    }
}
