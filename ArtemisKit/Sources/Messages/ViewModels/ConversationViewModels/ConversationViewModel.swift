//
//  ConversationViewModel.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

import APIClient
import Foundation
import Common
import SharedModels
import SharedServices
import UserStore

// swiftlint:disable file_length
@MainActor
class ConversationViewModel: BaseViewModel {

    @Published var dailyMessages: DataState<[Date: [Message]]> = .loading
    @Published var conversation: DataState<Conversation> = .loading
    @Published var course: DataState<Course> = .loading

    var shouldScrollToId: String?
    var websocketSubscriptionTask: Task<(), Never>?

    let courseId: Int
    let conversationId: Int64

    private var size = 50

    private let courseService: CourseService
    private let messagesService: MessagesService
    private let stompClient: ArtemisStompClient
    private let userSession: UserSession

    init(
        course: Course,
        conversation: Conversation,
        courseService: CourseService = CourseServiceFactory.shared,
        messagesService: MessagesService = MessagesServiceFactory.shared,
        stompClient: ArtemisStompClient = .shared,
        userSession: UserSession = .shared
    ) {
        self._course = Published(wrappedValue: .done(response: course))
        self.courseId = course.id
        self._conversation = Published(wrappedValue: .done(response: conversation))
        self.conversationId = conversation.id

        self.courseService = courseService
        self.messagesService = messagesService
        self.stompClient = stompClient
        self.userSession = userSession

        super.init()

        subscribeToConversationTopic()
    }

    deinit {
        websocketSubscriptionTask?.cancel()
    }
}

// MARK: - Internal

extension ConversationViewModel {

    // MARK: Load

    func loadFurtherMessages() async {
        size += 50
        if let dailyMessages = dailyMessages.value,
           let lastKey = dailyMessages.keys.min(),
           let lastMessage = dailyMessages[lastKey]?.first {
            shouldScrollToId = lastMessage.id.description
        }

        await loadMessages()
    }

    func loadMessages() async {
        let result = await messagesService.getMessages(for: courseId, and: conversationId, size: size)

        switch result {
        case .loading:
            dailyMessages = .loading
        case .failure(let error):
            dailyMessages = .failure(error: error)
        case .done(let response):
            var dailyMessages: [Date: [Message]] = [:]

            for message in response {
                if let date = message.creationDate?.startOfDay {
                    if dailyMessages[date] == nil {
                        dailyMessages[date] = [message]
                    } else {
                        dailyMessages[date]?.append(message)
                        dailyMessages[date] = dailyMessages[date]?.sorted {
                            $0.creationDate! < $1.creationDate!
                        }
                    }
                }
            }

            self.dailyMessages = .done(response: dailyMessages)
        }
    }

    func loadMessage(messageId: Int64) async -> DataState<Message> {
        // TODO: add API to only load one single message
        let result = await messagesService.getMessages(for: courseId, and: conversationId, size: size)

        switch result {
        case .loading:
            return .loading
        case .failure(let error):
            return .failure(error: error)
        case .done(let response):
            guard let message = response.first(where: { $0.id == messageId }) else {
                return .failure(error: UserFacingError(title: R.string.localizable.messageCouldNotBeLoadedError()))
            }
            return .done(response: message)
        }
    }

    func loadAnswerMessage(answerMessageId: Int64) async -> DataState<AnswerMessage> {
        // TODO: add API to only load one single answer message
        let result = await messagesService.getMessages(for: courseId, and: conversationId, size: size)

        switch result {
        case .loading:
            return .loading
        case .failure(let error):
            return .failure(error: error)
        case .done(let response):
            guard let message = response.first(where: { $0.answers?.contains(where: { $0.id == answerMessageId }) ?? false }),
                  let answerMessage = message.answers?.first(where: { $0.id == answerMessageId }) else {
                return .failure(error: UserFacingError(title: R.string.localizable.messageCouldNotBeLoadedError()))
            }
            return .done(response: answerMessage)
        }
    }

    // MARK: React

    func addReactionToMessage(for message: Message, emojiId: String) async -> DataState<Message> {
        isLoading = true
        let result: NetworkResponse
        if let reaction = message.getReactionFromMe(emojiId: emojiId) {
            result = await messagesService.removeReactionFromMessage(for: courseId, reaction: reaction)
        } else {
            result = await messagesService.addReactionToMessage(for: courseId, message: message, emojiId: emojiId)
        }
        switch result {
        case .notStarted, .loading:
            isLoading = false
            return .loading
        case .success:
            shouldScrollToId = nil
            let newMessage = await loadMessage(messageId: message.id)
            isLoading = false
            return newMessage
        case .failure(let error):
            isLoading = false
            if let apiClientError = error as? APIClientError {
                let userFacingError = UserFacingError(error: apiClientError)
                presentError(userFacingError: userFacingError)
                return .failure(error: userFacingError)
            } else {
                let userFacingError = UserFacingError(title: error.localizedDescription)
                presentError(userFacingError: userFacingError)
                return .failure(error: userFacingError)
            }
        }
    }

    func addReactionToAnswerMessage(for message: AnswerMessage, emojiId: String) async -> DataState<AnswerMessage> {
        isLoading = true
        let result: NetworkResponse
        if let reaction = message.getReactionFromMe(emojiId: emojiId) {
            result = await messagesService.removeReactionFromMessage(for: courseId, reaction: reaction)
        } else {
            result = await messagesService.addReactionToAnswerMessage(for: courseId, answerMessage: message, emojiId: emojiId)
        }
        switch result {
        case .notStarted, .loading:
            isLoading = false
            return .loading
        case .success:
            shouldScrollToId = nil
            let newMessage = await loadAnswerMessage(answerMessageId: message.id)
            isLoading = false
            return newMessage
        case .failure(let error):
            isLoading = false
            if let apiClientError = error as? APIClientError {
                let userFacingError = UserFacingError(error: apiClientError)
                presentError(userFacingError: userFacingError)
                return .failure(error: userFacingError)
            } else {
                let userFacingError = UserFacingError(title: error.localizedDescription)
                presentError(userFacingError: userFacingError)
                return .failure(error: userFacingError)
            }
        }
    }

    // MARK: Delete

    func deleteMessage(messageId: Int64?) async -> Bool {
        guard let messageId else {
            presentError(userFacingError: UserFacingError(title: R.string.localizable.deletionErrorLabel()))
            return false
        }

        let result = await messagesService.deleteMessage(for: courseId, messageId: messageId)

        switch result {
        case .notStarted, .loading:
            return false
        case .success:
            await loadMessages()
            return true
        case .failure(let error):
            presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            return false
        }
    }

    func deleteAnswerMessage(messageId: Int64?) async -> Bool {
        guard let messageId else {
            presentError(userFacingError: UserFacingError(title: R.string.localizable.deletionErrorLabel()))
            return false
        }

        let result = await messagesService.deleteAnswerMessage(for: courseId, anserMessageId: messageId)

        switch result {
        case .notStarted, .loading:
            return false
        case .success:
            await loadMessages()
            return true
        case .failure(let error):
            presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            return false
        }
    }
}

// MARK: - Private

private extension ConversationViewModel {

    // MARK: Initializer

    func subscribeToConversationTopic() {
        let topic: String
        if conversation.value?.baseConversation.type == .channel {
            topic = WebSocketTopic.makeChannelNotifications(courseId: courseId)
        } else if let id = userSession.user?.id {
            topic = WebSocketTopic.makeConversationNotifications(userId: id)
        } else {
            return
        }
        if stompClient.didSubscribeTopic(topic) {
            return
        }
        websocketSubscriptionTask = Task { [weak self] in
            guard let stream = self?.stompClient.subscribe(to: topic) else {
                return
            }

            for await message in stream {
                guard let messageWebsocketDTO = JSONDecoder.getTypeFromSocketMessage(type: MessageWebsocketDTO.self, message: message) else {
                    continue
                }

                guard let self else {
                    return
                }
                onMessageReceived(messageWebsocketDTO: messageWebsocketDTO)
            }
        }
    }

    // MARK: Receive message

    func onMessageReceived(messageWebsocketDTO: MessageWebsocketDTO) {
        // Guard message corresponds to conversation
        guard messageWebsocketDTO.post.conversation?.id == conversation.value?.id else {
            return
        }
        switch messageWebsocketDTO.action {
        case .create:
            handleNewMessage(messageWebsocketDTO.post)
        case .update:
            handleUpdateMessage(messageWebsocketDTO.post)
        case .delete:
            handleDeletedMessage(messageWebsocketDTO.post)
        default:
            return
        }
    }

    func handleNewMessage(_ newMessage: Message) {
        guard var dailyMessages = dailyMessages.value else {
            // messages not loaded yet
            return
        }

        if let date = newMessage.creationDate?.startOfDay {
            if dailyMessages[date] == nil {
                dailyMessages[date] = [newMessage]
            } else {
                guard !(dailyMessages[date]?.contains(newMessage) ?? false) else { return }
                dailyMessages[date]?.append(newMessage)
                dailyMessages[date] = dailyMessages[date]?.sorted(by: { $0.creationDate! < $1.creationDate! })
            }
        }

        shouldScrollToId = newMessage.id.description
        self.dailyMessages = .done(response: dailyMessages)
    }

    func handleUpdateMessage(_ updatedMessage: Message) {
        guard var dailyMessages = dailyMessages.value else {
            // messages not loaded yet
            return
        }

        guard let date = updatedMessage.creationDate?.startOfDay,
              let messageIndex = dailyMessages[date]?.firstIndex(where: { $0.id == updatedMessage.id }) else {
            log.error("Message with id \(updatedMessage.id) could not be updated")
            return
        }

        dailyMessages[date]?[messageIndex] = updatedMessage

        shouldScrollToId = nil
        self.dailyMessages = .done(response: dailyMessages)
    }

    func handleDeletedMessage(_ deletedMessage: Message) {
        guard var dailyMessages = dailyMessages.value else {
            // messages not loaded yet
            return
        }

        guard let date = deletedMessage.creationDate?.startOfDay else {
            log.error("Message with id \(deletedMessage.id) could not be updated")
            return
        }

        dailyMessages[date]?.removeAll(where: { deletedMessage.id == $0.id })

        shouldScrollToId = nil
        self.dailyMessages = .done(response: dailyMessages)
    }
}
