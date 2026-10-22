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
        case forwardMessage
    }

    enum ConditionalPresentation {
        case memberPicker
        case channelPicker
    }
}

@MainActor
@Observable
final class SendMessageViewModel {
    let course: CourseForOverviewDTO
    let conversation: Conversation
    let configuration: Configuration

    private let delegate: SendMessageViewModelDelegate
    private let messagesRepository: MessagesRepository
    private let messagesService: MessagesService
    private let userSession: UserSession
    private var hasLoadedContent = false
    private var lastPersistedDraft = ""

    // MARK: Loading

    var isLoading = false

    // MARK: Text

    let editor = MessageEditorDocument()
    var text: String {
        get { editor.markdown }
        set { editor.load(newValue) }
    }
    internal var uploadedImages = [String: UIImage]()
    var formattingExpanded = false
    var editorExpanded = false
    var showsLinkEditor = false

    var isEditing: Bool {
        switch configuration {
        case .message, .answerMessage:
            return false
        case .editMessage, .editAnswerMessage, .forwardMessage:
            return true
        }
    }

    var canSend: Bool {
        guard !editor.hasUnsupportedContent else { return false }
        return switch configuration {
        case .forwardMessage: true
        default: !text.isEmpty
        }
    }

    var canDiscardUnsupportedDraft: Bool {
        guard editor.hasUnsupportedContent else { return false }
        return switch configuration {
        case .message, .answerMessage: true
        default: false
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
        course: CourseForOverviewDTO,
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
        editor.onContentChange = { [weak self] in self?.persistDraft() }
    }
}

// MARK: - Actions

extension SendMessageViewModel {
    func discardUnsupportedDraft() {
        guard canDiscardUnsupportedDraft else { return }
        do {
            if let host = userSession.institution?.baseURL?.host() {
                switch configuration {
                case .message:
                    try messagesRepository.insertConversation(host: host, courseId: course.id,
                                                              conversationId: Int(conversation.id), messageDraft: "")
                case let .answerMessage(message, _):
                    try messagesRepository.insertMessage(host: host, courseId: course.id, conversationId: Int(conversation.id),
                                                         messageId: Int(message.id), answerMessageDraft: "")
                default:
                    return
                }
            }
            text = ""
            uploadedImages = [:]
            lastPersistedDraft = ""
        } catch {
            delegate.presentError(UserFacingError(title: error.localizedDescription))
        }
    }

    func performOnAppear() {
        // A retained composer can appear again after presenting a sheet or navigating to a thread.
        guard !hasLoadedContent else { return }
        do {
            switch configuration {
            case .message:
                guard let host = userSession.institution?.baseURL?.host() else { return }
                let conversation = try messagesRepository.fetchConversation(
                    host: host,
                    courseId: course.id,
                    conversationId: Int(conversation.id))
                text = conversation?.messageDraft ?? ""
            case let .answerMessage(message, _):
                guard let host = userSession.institution?.baseURL?.host() else { return }
                let message = try messagesRepository.fetchMessage(
                    host: host,
                    courseId: course.id,
                    conversationId: Int(conversation.id),
                    messageId: Int(message.id))
                text = message?.answerMessageDraft ?? ""
            case let .editMessage(message, _): text = message.content ?? ""
            case let .editAnswerMessage(message, _): text = message.content ?? ""
            case .forwardMessage: text = ""
            }
            lastPersistedDraft = text
            hasLoadedContent = true
        } catch {
            log.error(error)
        }
    }

    func performOnDisappear() {
        keyboardVisible = false
        persistDraft()
    }

    private func persistDraft() {
        // A retained, unchanged composer must not overwrite a newer composer on disappearance.
        // Hydration must also finish before native callbacks can write a draft.
        guard hasLoadedContent, !editor.hasUnsupportedContent, text != lastPersistedDraft else { return }
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
                    return
                }
                lastPersistedDraft = text
            }
        } catch {
            log.error(error)
        }
    }

    // MARK: Send Message

    func didTapSendButton() {
        guard canSend, !isLoading else { return }
        let sentText = text
        isLoading = true
        Task { @MainActor in
            guard canSend else {
                isLoading = false
                persistDraft()
                return
            }
            var result: NetworkResponse?
            switch configuration {
            case .message, .forwardMessage:
                result = await delegate.sendMessage(sentText) ? .success : .notStarted
                isLoading = false
            case let .answerMessage(message, _):
                result = await sendAnswerMessage(text: sentText, for: message)
            case let .editMessage(message, completion):
                var newMessage = message
                newMessage.content = sentText
                let success = await editMessage(message: newMessage)
                isLoading = false
                if success {
                    completion()
                }
            case let .editAnswerMessage(message, completion):
                var newMessage = message
                newMessage.content = sentText
                let success = await editAnswerMessage(answerMessage: newMessage)
                isLoading = false
                if success {
                    completion()
                }
            }
            if case .success = result, text == sentText {
                text = ""
                uploadedImages = [:]
            }
            // Persist the remaining draft before a thread reload can recreate its composer.
            // A failed send also keeps any text entered while the request was in flight.
            persistDraft()
            if case .success = result, case let .answerMessage(_, completion) = configuration {
                await completion()
            }
        }
    }

    private func sendAnswerMessage(text: String, for message: Message) async -> NetworkResponse {
        isLoading = true
        let result = await messagesService.sendAnswerMessage(for: course.id, message: message, content: text)
        switch result {
        case .notStarted, .loading:
            isLoading = false
        case .success:
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
            uploadedImages = [:]
            return true
        case .failure(let error):
            delegate.presentError(UserFacingError(title: error.localizedDescription))
            return false
        }
    }

    private func editAnswerMessage(answerMessage: AnswerMessage) async -> Bool {
        let result = await messagesService.editAnswerMessage(for: course.id, answerMessage: answerMessage)

        switch result {
        case .notStarted, .loading: return false
        case .success:
            uploadedImages = [:]
            return true
        case .failure(let error):
            delegate.presentError(UserFacingError(title: error.localizedDescription))
            return false
        }
    }
}
