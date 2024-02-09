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

    private let artemisStompClient = ArtemisStompClient.shared
    private let courseService: CourseService
    private let messagesService: MessagesService
    private let userSession = UserSession.shared

    init(
        course: Course,
        conversation: Conversation,
        courseService: CourseService = CourseServiceFactory.shared,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self._course = Published(wrappedValue: .done(response: course))
        self.courseId = course.id
        self._conversation = Published(wrappedValue: .done(response: conversation))
        self.conversationId = conversation.id

        self.courseService = courseService
        self.messagesService = messagesService

        super.init()

        subscribeToConversationTopic()
    }

    init(
        courseId: Int,
        conversationId: Int64,
        courseService: CourseService = CourseServiceFactory.shared,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self.courseId = courseId
        self.conversationId = conversationId
        self._conversation = Published(wrappedValue: .loading)
        self._course = Published(wrappedValue: .loading)

        self.courseService = courseService
        self.messagesService = messagesService

        super.init()

        Task {
            await loadConversation()
        }
        Task {
            await loadCourse()
        }

        subscribeToConversationTopic()
    }

    deinit {
        websocketSubscriptionTask?.cancel()
    }

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

    func sendMessage(text: String) async -> NetworkResponse {
        guard let conversation = conversation.value else {
            let error = UserFacingError(title: R.string.localizable.conversationNotLoaded())
            presentError(userFacingError: error)
            return .failure(error: error)
        }
        isLoading = true
        let result = await messagesService.sendMessage(for: courseId, conversation: conversation, content: text)
        switch result {
        case .notStarted, .loading:
            isLoading = false
        case .success:
            shouldScrollToId = "bottom"
            await loadMessages()
            isLoading = false
        case .failure(let error):
            isLoading = false
            if let apiClientError = error as? APIClientError {
                presentError(userFacingError: UserFacingError(error: apiClientError))
            } else {
                presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            }
        }
        return result
    }

    func sendAnswerMessage(text: String, for message: Message, completion: () async -> Void) async -> NetworkResponse {
        isLoading = true
        let result = await messagesService.sendAnswerMessage(for: courseId, message: message, content: text)
        switch result {
        case .notStarted, .loading:
            isLoading = false
        case .success:
            await completion()
            isLoading = false
        case .failure(let error):
            isLoading = false
            if let apiClientError = error as? APIClientError {
                presentError(userFacingError: UserFacingError(error: apiClientError))
            } else {
                presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            }
        }
        return result
    }

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

    func editMessage(message: Message) async -> Bool {
        let result = await messagesService.editMessage(for: courseId, message: message)

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

    func editAnswerMessage(answerMessage: AnswerMessage) async -> Bool {
        let result = await messagesService.editAnswerMessage(for: courseId, answerMessage: answerMessage)

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

// MARK: Start (initializer)

private extension ConversationViewModel {
    func loadConversation() async {
        let result = await messagesService.getConversations(for: courseId)

        switch result {
        case .loading:
            conversation = .loading
        case .failure(let error):
            conversation = .failure(error: error)
        case .done(let response):
            guard let conversation = response.first(where: { $0.id == conversationId }) else {
                self.conversation = .failure(error: UserFacingError(title: R.string.localizable.conversationNotLoaded()))
                return
            }
            self.conversation = .done(response: conversation)
        }
    }

    func loadCourse() async {
        let result = await courseService.getCourse(courseId: courseId)

        switch result {
        case .loading:
            course = .loading
        case .failure(let error):
            course = .failure(error: error)
        case .done(let response):
            course = .done(response: response.course)
        }
    }

    func subscribeToConversationTopic() {
        let topic: String
        if conversation.value?.baseConversation.type == .channel {
            topic = WebSocketTopic.makeChannelNotifications(courseId: courseId)
        } else if let id = UserSession.shared.user?.id {
            topic = WebSocketTopic.makeConversationNotifications(userId: id)
        } else {
            return
        }
        if artemisStompClient.didSubscribeTopic(topic) {
            return
        }
        websocketSubscriptionTask = Task { [weak self] in
            let stream = artemisStompClient.subscribe(to: topic)

            for await message in stream {
                guard let messageWebsocketDTO = JSONDecoder.getTypeFromSocketMessage(type: MessageWebsocketDTO.self, message: message) else {
                    continue
                }

                self?.onMessageReceived(messageWebsocketDTO: messageWebsocketDTO)
            }
        }
    }
}

// MARK: Receive message

private extension ConversationViewModel {
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
