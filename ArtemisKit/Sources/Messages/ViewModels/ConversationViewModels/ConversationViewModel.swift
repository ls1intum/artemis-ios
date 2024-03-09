//
//  ConversationViewModel.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

import APIClient
import Foundation
import Common
import Extensions
import SharedModels
import SharedServices
import UserStore

@MainActor
class ConversationViewModel: BaseViewModel {

    let course: Course
    let conversation: Conversation

    @Published var dailyMessages: DataState<[Date: [Message]]> = .loading
    @Published var offlineMessages: [ConversationOfflineMessageModel] = []

    var isAllowedToPost: Bool {
        guard let channel = conversation.baseConversation as? Channel else {
            return true
        }
        // Channel is archived
        if channel.isArchived ?? false {
            return false
        }
        // Channel is announcement channel and current user is not instructor
        if channel.isAnnouncementChannel ?? false && !(channel.hasChannelModerationRights ?? false) {
            return false
        }
        return true
    }

    var shouldScrollToId: String?
    var websocketSubscriptionTask: Task<(), Never>?

    private var size = 50

    private let messagesRepository: MessagesRepository
    private let messagesService: MessagesService
    private let stompClient: ArtemisStompClient
    private let userSession: UserSession

    init(
        course: Course,
        conversation: Conversation,
        messagesRepository: MessagesRepository = .shared,
        messagesService: MessagesService = MessagesServiceFactory.shared,
        stompClient: ArtemisStompClient = .shared,
        userSession: UserSession = .shared
    ) {
        self.course = course
        self.conversation = conversation

        self.messagesRepository = messagesRepository
        self.messagesService = messagesService
        self.stompClient = stompClient
        self.userSession = userSession

        super.init()

        subscribeToConversationTopic()
        fetchConversationOfflineMessages()
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
        let result = await messagesService.getMessages(for: course.id, and: conversation.id, size: size)
        self.dailyMessages = result.map { messages in
            var dailyMessages: [Date: [Message]] = [:]
            for message in messages {
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
            return dailyMessages
        }
    }

    func loadMessage(messageId: Int64) async -> DataState<Message> {
        // TODO: add API to only load one single message
        let result = await messagesService.getMessages(for: course.id, and: conversation.id, size: size)
        return result.flatMap { messages in
            guard let message = messages.first(where: { $0.id == messageId }) else {
                return .failure(UserFacingError(title: R.string.localizable.messageCouldNotBeLoadedError()))
            }
            return .success(message)
        }
    }

    func loadAnswerMessage(answerMessageId: Int64) async -> DataState<AnswerMessage> {
        // TODO: add API to only load one single answer message
        let result = await messagesService.getMessages(for: course.id, and: conversation.id, size: size)
        return result.flatMap { messages in
            guard let message = messages.first(where: { $0.answers?.contains(where: { $0.id == answerMessageId }) ?? false }),
                  let answerMessage = message.answers?.first(where: { $0.id == answerMessageId }) else {
                return .failure(UserFacingError(title: R.string.localizable.messageCouldNotBeLoadedError()))
            }
            return .success(answerMessage)
        }
    }

    // MARK: Send message

    func sendMessage(text: String) async -> NetworkResponse {
        if let host = userSession.institution?.baseURL?.host() {
            do {
                offlineMessages.append(
                    try messagesRepository.insertConversationOfflineMessage(
                        host: host, courseId: course.id, conversationId: Int(conversation.id), date: .now, text: text
                    )
                )
            } catch {
                log.error(error)
            }
        }
        return .success
    }

    // MARK: React

    func addReactionToMessage(for message: Message, emojiId: String) async -> DataState<Message> {
        isLoading = true
        let result: NetworkResponse
        if let reaction = message.getReactionFromMe(emojiId: emojiId) {
            result = await messagesService.removeReactionFromMessage(for: course.id, reaction: reaction)
        } else {
            result = await messagesService.addReactionToMessage(for: course.id, message: message, emojiId: emojiId)
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
            result = await messagesService.removeReactionFromMessage(for: course.id, reaction: reaction)
        } else {
            result = await messagesService.addReactionToAnswerMessage(for: course.id, answerMessage: message, emojiId: emojiId)
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

        let result = await messagesService.deleteMessage(for: course.id, messageId: messageId)

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

        let result = await messagesService.deleteAnswerMessage(for: course.id, anserMessageId: messageId)

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
        if conversation.baseConversation.type == .channel {
            topic = WebSocketTopic.makeChannelNotifications(courseId: course.id)
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

    func fetchConversationOfflineMessages() {
        if let host = userSession.institution?.baseURL?.host() {
            do {
                let messages = try messagesRepository.fetchConversationOfflineMessages(
                    host: host,
                    courseId: course.id,
                    conversationId: Int(conversation.id))
                self.offlineMessages = messages
            } catch {
                log.error(error)
            }
        }
    }

    // MARK: Receive message

    func onMessageReceived(messageWebsocketDTO: MessageWebsocketDTO) {
        // Guard message corresponds to conversation
        guard messageWebsocketDTO.post.conversation?.id == conversation.id else {
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

// MARK: - ConversationViewModel+OfflineMessageCellModelDelegate

extension OfflineMessageCellModelDelegate {
    init(_ viewModel: ConversationViewModel) {
        self.init { message in
            viewModel.shouldScrollToId = "bottom"
            await viewModel.loadMessages()
            if let index = viewModel.offlineMessages.firstIndex(of: message) {
                viewModel.offlineMessages.remove(at: index)
            }
        }
    }
}
