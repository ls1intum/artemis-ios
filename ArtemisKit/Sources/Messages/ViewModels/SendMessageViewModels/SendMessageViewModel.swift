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
import UserStore

extension SendMessageViewModel {
    enum Configuration {
        case message
        case answerMessage(Message, MessageDetailViewModel)
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

@MainActor
@Observable
final class SendMessageViewModel {
    let course: Course
    let conversation: Conversation
    let configuration: Configuration

    private let delegate: SendMessageViewModelDelegate
    private let messagesRepository: MessagesRepository
    private let messagesService: MessagesService
    private let userSession: UserSession

    // MARK: Loading

    var isLoading = false

    // MARK: Text

    var text = ""

    var isEditing: Bool {
        switch configuration {
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
        configuration: Configuration,
        delegate: SendMessageViewModelDelegate,
        messagesRepository: MessagesRepository = .shared,
        messagesService: MessagesService = MessagesServiceFactory.shared,
        userSession: UserSession = .shared
    ) {
        self.course = course
        self.conversation = conversation
        self.configuration = configuration

        self.delegate = delegate
        self.messagesRepository = messagesRepository
        self.messagesService = messagesService
        self.userSession = userSession
    }
}

// MARK: - Actions

extension SendMessageViewModel {
    func performOnAppear() {
        do {
            switch configuration {
            case .message:
                if let host = userSession.institution?.baseURL?.host() {
                    let conversation = try messagesRepository.fetchConversation(
                        host: host,
                        courseId: course.id,
                        conversationId: Int(conversation.id))
                    text = conversation?.messageDraft ?? ""
                }
            case let .answerMessage(message, _):
                if let host = userSession.institution?.baseURL?.host() {
                    let message = try messagesRepository.fetchMessage(
                        host: host,
                        courseId: course.id,
                        conversationId: Int(conversation.id),
                        messageId: Int(message.id))
                    text = message?.answerMessageDraft ?? ""
                }
            case let .editMessage(message, _):
                text = message.content ?? ""
            case let .editAnswerMessage(message, _):
                text = message.content ?? ""
            }
        } catch {
            log.error(error)
        }
    }

    func performOnDisappear() {
        do {
            if let host = userSession.institution?.baseURL?.host() {
                switch configuration {
                case .message:
                    try messagesRepository.insertConversation(
                        host: host,
                        courseId: course.id,
                        conversationId: Int(conversation.id),
                        messageDraft: text)
                case let .answerMessage(message, _):
                    try messagesRepository.insertMessage(
                        host: host,
                        courseId: course.id,
                        conversationId: Int(conversation.id),
                        messageId: Int(message.id),
                        answerMessageDraft: text)
                default:
                    break
                }
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
            switch configuration {
            case .message:
                delegate.sendMessage(text)
                result = .success
                isLoading = false
            case let .answerMessage(_, viewModel):
                await viewModel.sendAnswerMessage(text: text)
                viewModel.shouldScrollToId = "bottom"
                result = .success
                isLoading = false
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
