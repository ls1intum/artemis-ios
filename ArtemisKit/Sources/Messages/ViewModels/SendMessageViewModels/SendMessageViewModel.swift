//
//  SendMessageViewModel.swift
//
//
//  Created by Nityananda Zbil on 22.02.24.
//

import Foundation
import SharedModels

enum SendMessageType {
    case message
    case answerMessage(Message, () async -> Void)
    case editMessage(Message, () -> Void)
    case editAnswerMessage(AnswerMessage, () -> Void)
}

@Observable
final class SendMessageViewModel {

    enum ConditionalPresentation {
        case memberPicker
        case channelPicker
    }

    enum ModalPresentation: Identifiable {
        case exercisePicker
        case lecturePicker

        var id: Self {
            self
        }
    }

    let sendMessageType: SendMessageType

    var text: String = ""

    var isEditing: Bool {
        switch sendMessageType {
        case .message, .answerMessage:
            return false
        case .editMessage, .editAnswerMessage:
            return true
        }
    }

    // MARK: Presentation

    var conditionalPresentation: ConditionalPresentation? {
        if !isMemberPickerSuppressed, searchMember() != nil {
            .memberPicker
        } else if !isChannelPickerSuppressed, searchChannel() != nil {
            .channelPicker
        } else {
            nil
        }
    }

    var isMemberPickerSuppressed = false
    var isChannelPickerSuppressed = false

    var modalPresentation: ModalPresentation?

    // MARK: Life cycle

    init(sendMessageType: SendMessageType) {
        self.sendMessageType = sendMessageType
    }
}

// MARK: - Actions

extension SendMessageViewModel {
    func performOnAppear() {
        switch sendMessageType {
        case let .editMessage(message, _):
            text = message.content ?? ""
        case let .editAnswerMessage(message, _):
            text = message.content ?? ""
        default:
            break
        }
    }

    func didTapAtButton() {
        if conditionalPresentation == .memberPicker {
            isMemberPickerSuppressed = true
        } else {
            isMemberPickerSuppressed = false
            text += "@"
        }
    }

    func didTapNumberButton() {
        if conditionalPresentation == .channelPicker {
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
        guard let candidate = searchMember(),
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
