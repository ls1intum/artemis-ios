//
//  SendMessageViewModel.swift
//
//
//  Created by Nityananda Zbil on 22.02.24.
//

import Foundation
import SharedModels

@Observable
final class SendMessageViewModel {

    enum Presentation {
        case memberPicker
        case channelPicker
    }

    var text: String = "" {
        didSet {
            updatePresentation()
        }
    }

    private(set) var presentation: Presentation?

    var isMemberPickerSuppressed = false {
        didSet {
            updatePresentation()
        }
    }

    var isChannelPickerSuppressed = false {
        didSet {
            updatePresentation()
        }
    }

    var isExercisePickerPresented = false
    var isLecturePickerPresented = false
}

// MARK: - Actions

extension SendMessageViewModel {
    func didTapAtButton() {
        if isMemberPickerPresented {
            isMemberPickerSuppressed = true
        } else {
            isMemberPickerSuppressed = false
            text += "@"
        }
    }

    func didTapNumberButton() {
        if isChannelPickerPresented {
            isChannelPickerSuppressed = true
        } else {
            isChannelPickerSuppressed = false
            text += "#"
        }
    }

    // MARK: Search and Replace

    func searchChannel() -> Substring? {
        let matches = text.matches(of: #/#(?<candidate>[\w-]*)/#)
        return matches.last?.candidate
    }

    func replace(channel: ChannelIdAndNameDTO) {
        guard let candidate = searchChannel() else {
            return
        }

        // Replaces all occurrences. Otherwise, we need to get the match.
        let range = Range<String.Index>?.none

        text = text.replacingOccurrences(
            of: "#" + candidate,
            with: "[channel]\(channel.name)(\(channel.id))[/channel]",
            range: range)
    }

    func searchMember() -> Substring? {
        let matches = text.matches(of: #/@(?<candidate>[\w]*)/#)
        return matches.last?.candidate
    }

    func replace(member: UserNameAndLoginDTO) {
        guard let candidate = searchChannel(),
              let name = member.name, let login = member.login else {
            return
        }

        // Replaces all occurrences. Otherwise, we need to get the match.
        let range = Range<String.Index>?.none

        text = text.replacingOccurrences(
            of: "@" + candidate,
            with: "[user]\(name)(\(login))[/user]",
            range: range)
    }
}

// MARK: - Presentation

extension SendMessageViewModel {
    var isMemberPickerPresented: Bool {
        presentation == .memberPicker
    }

    var isChannelPickerPresented: Bool {
        presentation == .channelPicker
    }
}

private extension SendMessageViewModel {
    func updatePresentation() {
        switch (
            presentation,
            searchMember(),
            searchChannel()
        ) {
        case (_, .some, _) where !isMemberPickerSuppressed:
            presentation = .memberPicker
        case (_, _, .some) where !isChannelPickerSuppressed:
            presentation = .channelPicker
        case (.some, _, _):
            fallthrough
        default:
            presentation = nil
        }
    }
}
