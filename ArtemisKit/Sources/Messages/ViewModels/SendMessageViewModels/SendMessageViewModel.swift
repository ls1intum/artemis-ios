//
//  SendMessageViewModel.swift
//
//
//  Created by Nityananda Zbil on 22.02.24.
//

import APIClient
import Common
import SharedModels
import SwiftUI
import UserStore

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
    internal var selection: TextSelection?
    var textSelection: Binding<TextSelection?> {
        Binding {
            return self.selection
        } set: { newValue in
            // Ignore updates if text field is not focused
            if !self.keyboardVisible && newValue != nil {
                return
            }
            self.selection = newValue
        }
    }

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

    var wantsToAddMessageMentionContentType: MessageMentionContentType?
    var presentKeyboardOnAppear: Bool
    var keyboardVisible = false

    // MARK: Life cycle

    init(
        course: Course,
        conversation: Conversation,
        configuration: Configuration,
        delegate: SendMessageViewModelDelegate,
        presentKeyboardOnAppear: Bool = false,
        messagesRepository: MessagesRepository? = nil,
        messagesService: MessagesService = MessagesServiceFactory.shared,
        userSession: UserSession = UserSessionFactory.shared
    ) {
        self.course = course
        self.conversation = conversation
        self.configuration = configuration
        self.presentKeyboardOnAppear = presentKeyboardOnAppear

        self.delegate = delegate
        self.messagesRepository = messagesRepository ?? .shared
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
        keyboardVisible = false
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

    func insertImageMention(path: String) {
        appendToSelection(before: "![", after: "](\(path))", placeholder: "image")
    }

    func insertFileMention(path: String, fileName: String) {
        appendToSelection(before: "[", after: "](\(path))", placeholder: fileName)
    }

    /// Prepends/Appends the given snippets to text the user has selected.
    private func appendToSelection(before: String, after: String, placeholder: String) {
        let placeholderText = "\(before)\(placeholder)\(after)"
        var shouldSelectPlaceholder = false

        if let selection = selection {
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
                if !shouldSelectPlaceholder, let endIndex = text.range(of: newText)?.upperBound {
                    self.selection = TextSelection(insertionPoint: endIndex)
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
                    selection = TextSelection(range: range.clamped(to: placeholderRange))
                }
            }
        }
    }

    // MARK: Send Message

    func didTapSendButton() {
        isLoading = true
        Task { @MainActor in
            var result: NetworkResponse?
            switch configuration {
            case .message:
                await delegate.sendMessage(text)
                result = .success
                isLoading = false
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
                selection = nil
                text = ""
            default:
                return
            }
        }
    }

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

    private func editMessage(message: Message) async -> Bool {
        let result = await messagesService.editMessage(for: course.id, message: message)

        switch result {
        case .notStarted, .loading:
            return false
        case .success:
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

        // Replaces all occurrences. Otherwise, we need to get the match.
        let range = Range<String.Index>?.none
        text = text.replacingOccurrences(
            of: "@" + candidate,
            with: "[user]\(name)(\(login))[/user]",
            range: range)
    }
}
