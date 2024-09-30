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

    @Published var conversation: Conversation

    @Published var messages: Set<IdentifiableMessage> = []
    /// Tracks added and removed messages.
    private var diff = 0
    private var page = 0

    @Published var offlineMessages: [ConversationOfflineMessageModel] = []

    @Published var isConversationInfoSheetPresented = false
    @Published var selectedMessageId: Int64?
    var isPerformingMessageAction = false

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
    var subscription: Task<(), Never>?

    fileprivate let messagesRepository: MessagesRepository
    private let messagesService: MessagesService
    private let stompClient: ArtemisStompClient
    private let userSession: UserSession

    init(
        course: Course,
        conversation: Conversation,
        messagesRepository: MessagesRepository? = nil,
        messagesService: MessagesService = MessagesServiceFactory.shared,
        stompClient: ArtemisStompClient = .shared,
        userSession: UserSession = UserSessionFactory.shared
    ) {
        self.course = course
        self.conversation = conversation

        self.messagesRepository = messagesRepository ?? .shared
        self.messagesService = messagesService
        self.stompClient = stompClient
        self.userSession = userSession

        super.init()

        subscribeToConversationTopic()
        fetchOfflineMessages()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateFavorites(notification:)),
                                               name: .favoriteConversationChanged,
                                               object: nil)
    }

    deinit {
        subscription?.cancel()
    }

    /// Saves changes to offline saved data. Call this whenever the view is dismissed.
    func saveContext() {
        messagesRepository.save()
    }
}

// MARK: - Internal

extension ConversationViewModel {

    // MARK: Load

    func loadEarlierMessages() async {
        let (quotient, _) = diff.quotientAndRemainder(dividingBy: MessagesServiceImpl.GetMessagesRequest.size)
        page += 1 + quotient
        await loadMessages()
    }

    func loadMessages() async {
        let result = await messagesService.getMessages(for: course.id, and: conversation.id, page: page)
        switch result {
        case .loading:
            break
        case let .done(response: response):
            // Keep existing members in new, i.e., update existing members in messages.
            messages = Set(response.map(IdentifiableMessage.init)).union(messages)
            if page > 0, response.count < MessagesServiceImpl.GetMessagesRequest.size {
                page -= 1
            }
            diff = 0
        case let .failure(error: error):
            presentError(userFacingError: error)
        }
    }

    func loadMessage(messageId: Int64) async -> DataState<Message> {
        // TODO: add API to only load one single message
        let result = await messagesService.getMessages(for: course.id, and: conversation.id, page: page)
        return result.flatMap { messages in
            guard let message = messages.first(where: { $0.id == messageId }) else {
                return .failure(UserFacingError(title: R.string.localizable.messageCouldNotBeLoadedError()))
            }
            return .success(message)
        }
    }

    func loadAnswerMessage(answerMessageId: Int64) async -> DataState<AnswerMessage> {
        // TODO: add API to only load one single answer message
        let result = await messagesService.getMessages(for: course.id, and: conversation.id, page: page)
        return result.flatMap { messages in
            guard let message = messages.first(where: { $0.answers?.contains(where: { $0.id == answerMessageId }) ?? false }),
                  let answerMessage = message.answers?.first(where: { $0.id == answerMessageId }) else {
                return .failure(UserFacingError(title: R.string.localizable.messageCouldNotBeLoadedError()))
            }
            return .success(answerMessage)
        }
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
            return true
        case .failure(let error):
            presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            return false
        }
    }

    // MARK: Mark as Resolving, Pin

    func toggleResolving(for message: AnswerMessage) async -> Bool {
        isLoading = true

        var message = message
        message.resolvesPost = !(message.resolvesPost ?? false)

        let result = await messagesService.editAnswerMessage(for: course.id, answerMessage: message)
        isLoading = false
        switch result {
        case .failure(let error):
            if let apiClientError = error as? APIClientError {
                let userFacingError = UserFacingError(error: apiClientError)
                presentError(userFacingError: userFacingError)
            } else {
                let userFacingError = UserFacingError(title: error.localizedDescription)
                presentError(userFacingError: userFacingError)
            }
        case .success:
            return true
        default:
            break
        }
        return false
    }

    func togglePinned(for message: Message) async -> DataState<any BaseMessage> {
        isLoading = true

        let isPinned = message.displayPriority == .pinned

        let result = await messagesService.updateMessageDisplayPriority(for: Int64(course.id), messageId: message.id, displayPriority: isPinned ? .noInformation : .pinned)
        isLoading = false
        switch result {
        case .failure(let error):
            presentError(userFacingError: error)
            return .failure(error: error)
        case .done(let message):
            return .done(response: message)
        case .loading:
            return .loading
        }
    }
}

// MARK: - Fileprivate

fileprivate extension ConversationViewModel {

    // MARK: Send message

    func sendMessage(text: String) async {
        if let host = userSession.institution?.baseURL?.host() {
            do {
                let offlineMessage = try messagesRepository.insertConversationOfflineMessage(
                    host: host, courseId: course.id, conversationId: Int(conversation.id), date: .now, text: text
                )
                offlineMessages.append(offlineMessage)
            } catch {
                log.error(error)
            }
        } else {
            log.verbose("Host is nil")
        }
    }
}

// MARK: - Private

private extension ConversationViewModel {

    // MARK: Initializer

    func subscribeToConversationTopic() {
        let topic: String
        if conversation.baseConversation.type == .channel,
           let channel = conversation.baseConversation as? Channel,
           channel.isCourseWide == true {
            topic = WebSocketTopic.makeChannelNotifications(courseId: course.id)
        } else if let id = userSession.user?.id {
            topic = WebSocketTopic.makeConversationNotifications(userId: id)
        } else {
            return
        }
        if stompClient.didSubscribeTopic(topic) {
            /// These web socket topics are the same across multiple channels.
            /// We might need to wait until a previously open conversation has unsubscribed
            /// before we can subscribe again
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
                DispatchQueue.main.async { [weak self] in
                    self?.subscribeToConversationTopic()
                }
            }
            return
        }
        subscription = Task { [weak self] in
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

    func fetchOfflineMessages() {
        if let host = userSession.institution?.baseURL?.host() {
            do {
                self.offlineMessages = try messagesRepository.fetchConversationOfflineMessages(
                    host: host, courseId: course.id, conversationId: Int(conversation.id)
                )
            } catch {
                log.error(error)
            }
        } else {
            log.verbose("Host is nil")
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
            handle(new: messageWebsocketDTO.post)
        case .update:
            handle(update: messageWebsocketDTO.post)
        case .delete:
            handle(delete: messageWebsocketDTO.post)
        default:
            return
        }
    }

    func handle(new message: Message) {
        shouldScrollToId = message.id.description
        let (inserted, _) = messages.insert(.message(message))
        if inserted {
            diff += 1
        }
    }

    func handle(update message: Message) {
        shouldScrollToId = nil
        if messages.contains(.of(id: message.id)) {
            let oldMessage = messages.first { $0.id == message.id }

            // We do not get `authorRole` via websockets, thus we need to manually keep it
            var newMessage = message
            newMessage.authorRole = newMessage.authorRole ?? oldMessage?.rawValue.authorRole
            // Same for answers
            newMessage.answers = newMessage.answers?.map { answer in
                var newAnswer = answer
                let oldAnswer = oldMessage?.rawValue.answers?.first { $0.id == answer.id }
                newAnswer.authorRole = newAnswer.authorRole ?? oldAnswer?.authorRole
                return newAnswer
            }

            messages.update(with: .message(newMessage))
        }
    }

    func handle(delete message: Message) {
        shouldScrollToId = nil
        let equal = messages.remove(.message(message))
        if equal != nil {
            diff -= 1
        }
    }

    // Change favorites
    @objc
    private func updateFavorites(notification: Foundation.Notification) {
        let isFavorite = notification.userInfo?[conversation.id] as? Bool ?? conversation.baseConversation.isFavorite
        if var convo = conversation.baseConversation as? Channel {
            convo.isFavorite = isFavorite
            conversation = .channel(conversation: convo)
        } else if var convo = conversation.baseConversation as? GroupChat {
            convo.isFavorite = isFavorite
            conversation = .groupChat(conversation: convo)
        } else if var convo = conversation.baseConversation as? OneToOneChat {
            convo.isFavorite = isFavorite
            conversation = .oneToOneChat(conversation: convo)
        }
    }
}

// MARK: - ConversationViewModel+SendMessageViewModelDelegate

extension SendMessageViewModelDelegate {
    init(_ conversationViewModel: ConversationViewModel) {
        self.presentError = conversationViewModel.presentError
        self.sendMessage = conversationViewModel.sendMessage
    }
}

// MARK: - ConversationViewModel+ConversationOfflineSectionModelDelegate

extension ConversationOfflineSectionModelDelegate {
    init(_ conversationViewModel: ConversationViewModel) {
        self.didSendOfflineMessage = { message in
            if let index = conversationViewModel.offlineMessages.firstIndex(of: message) {
                let message = conversationViewModel.offlineMessages.remove(at: index)
                conversationViewModel.messagesRepository.delete(conversationOfflineMessage: message)
            }
        }
    }
}
