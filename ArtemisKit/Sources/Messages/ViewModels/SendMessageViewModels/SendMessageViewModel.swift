//
//  SendMessageViewModel.swift
//
//
//  Created by Nityananda Zbil on 22.02.24.
//

import APIClient
import Common
import Foundation
import SharedModels

extension SendMessageViewModel {
    enum Configuration {
        case message
        case answerMessage(Message, () async -> Void)
        case editMessage(Message, () -> Void)
        case editAnswerMessage(AnswerMessage, () -> Void)
    }

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
}

@Observable
final class SendMessageViewModel {
    let course: Course
    let conversation: Conversation
    let sendMessageType: Configuration

    private let delegate: SendMessageViewModelDelegate
    private let messagesService: MessagesService

    // MARK: Loading

    var isLoading = false

    // MARK: Text

    var text = ""

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

    init(
        course: Course,
        conversation: Conversation,
        sendMessageType: Configuration,
        delegate: SendMessageViewModelDelegate,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self.course = course
        self.conversation = conversation
        self.sendMessageType = sendMessageType

        self.delegate = delegate
        self.messagesService = messagesService
    }
}

// MARK: - Actions

extension SendMessageViewModel {
    @MainActor
    func performOnAppear() {
        switch sendMessageType {
        case let .editMessage(message, _):
            text = message.content ?? ""
        case let .editAnswerMessage(message, _):
            text = message.content ?? ""
        default:
            do {
                let conversations = try AnyRepository.shared.fetch(remoteId: Int(conversation.id))
                if let first = conversations.first {
                    text = first.draft
                }
            } catch {
                log.error(error)
            }
        }
    }

    @MainActor
    func performOnDisappear() {
        do {
            if !text.isEmpty {
                try AnyRepository.shared.insert(conversation: Schema.Conversation(remoteId: Int(conversation.id), draft: text))
            }
        } catch {
            log.error(error)
        }
    }

    // MARK: Toolbar

    func didTapBoldButton() {
        text.append("****")
    }

    func didTapItalicButton() {
        text.append("**")
    }

    func didTapUnderlineButton() {
        text.append("<ins></ins>")
    }

    func didTapBlockquoteButton() {
        text.append("> Reference")
    }

    func didTapCodeButton() {
        text.append("``")
    }

    func didTapCodeBlockButton() {
        text.append("""
                    ```java
                    Source Code
                    ```
                    """)
    }

    func didTapLinkButton() {
        text.append("[](http://)")
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

    // MARK: Send Message

    func didTapSendButton() {
        isLoading = true
        Task { @MainActor in
            var result: NetworkResponse?
            switch sendMessageType {
            case .message:
                result = await sendMessage(text: text)
            case let .answerMessage(message, completion):
                result = await sendAnswerMessage(text: text, for: message, completion: completion)
            case let .editMessage(message, completion):
                var newMessage = message
                newMessage.content = text
                let success = await editMessage(message: newMessage)
                isLoading = false
                if success {
                    completion()
                }
            case let .editAnswerMessage(message, completion):
                var newMessage = message
                newMessage.content = text
                let success = await editAnswerMessage(answerMessage: newMessage)
                isLoading = false
                if success {
                    completion()
                }
            }
            switch result {
            case .success:
                text = ""
            default:
                return
            }
        }
    }

    @MainActor
    private func sendMessage(text: String) async -> NetworkResponse {
        isLoading = true
        let result = await messagesService.sendMessage(for: course.id, conversation: conversation, content: text)
        switch result {
        case .notStarted, .loading:
            isLoading = false
        case .success:
            delegate.scrollToId("bottom")
            await delegate.loadMessages()
            isLoading = false
        case .failure(let error):
            isLoading = false
            if let apiClientError = error as? APIClientError {
                delegate.presentError(UserFacingError(error: apiClientError))
            } else {
                delegate.presentError(UserFacingError(title: error.localizedDescription))
            }
        }
        return result
    }

    @MainActor
    private func sendAnswerMessage(text: String, for message: Message, completion: () async -> Void) async -> NetworkResponse {
        isLoading = true
        let result = await messagesService.sendAnswerMessage(for: course.id, message: message, content: text)
        switch result {
        case .notStarted, .loading:
            isLoading = false
        case .success:
            await completion()
            isLoading = false
        case .failure(let error):
            isLoading = false
            if let apiClientError = error as? APIClientError {
                delegate.presentError(UserFacingError(error: apiClientError))
            } else {
                delegate.presentError(UserFacingError(title: error.localizedDescription))
            }
        }
        return result
    }

    @MainActor
    private func editMessage(message: Message) async -> Bool {
        let result = await messagesService.editMessage(for: course.id, message: message)

        switch result {
        case .notStarted, .loading:
            return false
        case .success:
            await delegate.loadMessages()
            return true
        case .failure(let error):
            delegate.presentError(UserFacingError(title: error.localizedDescription))
            return false
        }
    }

    @MainActor
    private func editAnswerMessage(answerMessage: AnswerMessage) async -> Bool {
        let result = await messagesService.editAnswerMessage(for: course.id, answerMessage: answerMessage)

        switch result {
        case .notStarted, .loading:
            return false
        case .success:
            await delegate.loadMessages()
            return true
        case .failure(let error):
            delegate.presentError(UserFacingError(title: error.localizedDescription))
            return false
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
