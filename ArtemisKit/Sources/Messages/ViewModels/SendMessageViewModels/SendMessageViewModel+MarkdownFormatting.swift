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

    func didTapLinkButton() { showsLinkEditor = true }

    func didTapAtButton() {
        isMemberPickerSuppressed = false
        editor.beginCompletion("@")
    }

    func didTapNumberButton() {
        isChannelPickerSuppressed = false
        editor.beginCompletion("#")
    }

    func searchChannel() -> Substring? {
        guard let completion = editor.completion, completion.trigger == "#" else { return nil }
        return Substring(completion.query)
    }

    func replace(channel: ChannelIdAndNameDTO) {
        guard let completion = editor.completion, completion.trigger == "#" else { return }
        editor.insertMarkup("[channel]\(channel.name)(\(channel.id))[/channel]", replacing: completion.range)
    }

    func searchMember() -> Substring? {
        guard let completion = editor.completion, completion.trigger == "@" else { return nil }
        return Substring(completion.query)
    }

    func replace(member: UserNameAndLoginDTO) {
        guard let completion = editor.completion, completion.trigger == "@", let name = member.name, let login = member.login else { return }
        editor.insertMarkup("[user]\(name)(\(login))[/user]", replacing: completion.range)
    }

    // MARK: File uploads

    func insertFileMention(path: String, fileName: String) {
        editor.insertMarkup("[\(fileName)](\(path))")
    }

    func insertImageMention(path: String, image: UIImage? = nil) {
        editor.insertMarkup("![image](\(path))")

        // Save uploaded image locally for showing attachment preview
        if let image {
            uploadedImages[path] = image
        }
    }

    func removeImage(name: String, path: String) {
        editor.removeMarkup("![\(name)](\(path))")
    }

    var mentionedImages: [(name: String, path: String, image: UIImage)] {
        let pattern = #"\!\[([^\]]+)\]\(([^\)]+)\)"#
        var results = [(String, String, UIImage)]()

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

            for match in matches {
                if let nameRange = Range(match.range(at: 1), in: text),
                   let pathRange = Range(match.range(at: 2), in: text) {
                    let name = String(text[nameRange])
                    let path = String(text[pathRange])
                    if let image = uploadedImages[path] {
                        results.append((name, path, image))
                    }
                }
            }
        } catch {
            print("Invalid regex: \(error)")
        }
        return results
    }
}
