//
//  MessagesTabViewModel.swift
//
//
//  Created by Sven Andabaka on 03.04.23.
//

import APIClient
import Combine
import Common
import Foundation
import SharedModels
import SwiftUI
import UserStore

@MainActor
class MessagesAvailableViewModel: BaseViewModel {

    @Published var allConversations: DataState<[Conversation]> = .loading
    @Published var isCodeOfConductPresented = false

    var isDirectMessagingEnabled: Bool {
        course.courseInformationSharingConfiguration == .communicationAndMessaging
    }

    let course: Course
    let courseId: Int

    private let messagesService: MessagesService
    private let userSession: UserSession

    private var subscriptions = Set<AnyCancellable>()

    init(
        course: Course,
        messagesService: MessagesService = MessagesServiceFactory.shared,
        userSession: UserSession = UserSessionFactory.shared
    ) {
        self.course = course
        self.courseId = course.id

        self.messagesService = messagesService
        self.userSession = userSession

        super.init()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateFavorites(notification:)),
                                               name: .favoriteConversationChanged,
                                               object: nil)
    }

    deinit {
        SocketConnectionHandler.shared.cancelSubscriptions()
        subscriptions.forEach {
            $0.cancel()
        }
        subscriptions = []
    }

    func subscribeToWebsocketUpdates() {
        guard let userId = userSession.user?.id else {
            log.debug("User could not be found. Subscribe to Websocket updates not possible")
            return
        }

        guard subscriptions.isEmpty else {
            // Already subscribed
            return
        }

        let socketConnection = SocketConnectionHandler.shared

        socketConnection
            .conversationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conversationWebsocketDTO in
                guard let self else {
                    return
                }
                onConversationMembershipMessageReceived(conversationWebsocketDTO: conversationWebsocketDTO)
            }
            .store(in: &subscriptions)

        socketConnection
            .messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messageWebsocketDTO in
                guard let self else {
                    return
                }
                onNewSocketMessageReceived(messageWebsocketDTO: messageWebsocketDTO)
            }
            .store(in: &subscriptions)

        socketConnection.subscribeToMembershipNotifications(courseId: courseId, userId: userId)
        socketConnection.subscribeToChannelNotifications(courseId: courseId)
        socketConnection.subscribeToConversationNotifications(userId: userId)
    }

    func loadConversations() async {
        let result = await messagesService.getConversations(for: courseId)
        allConversations = result
    }

    @objc
    private func updateFavorites(notification: Foundation.Notification) {
        // User Info contains:
        // - Key: Conversation ID
        // - Value: New Value for isFavorite
        notification.userInfo?.forEach { id, isFavorite in
            guard let id = id as? Int64,
                  let isFavorite = isFavorite as? Bool else { return }

            // Find and update the corresponding conversation
            let updatedConversations = allConversations.value?.map { conversation in
                var newConversation = conversation
                if conversation.id == id {
                    if var convo = conversation.baseConversation as? Channel {
                        convo.isFavorite = isFavorite
                        newConversation = .channel(conversation: convo)
                    } else if var convo = conversation.baseConversation as? GroupChat {
                        convo.isFavorite = isFavorite
                        newConversation = .groupChat(conversation: convo)
                    } else if var convo = conversation.baseConversation as? OneToOneChat {
                        convo.isFavorite = isFavorite
                        newConversation = .oneToOneChat(conversation: convo)
                    }
                }
                return newConversation
            }
            allConversations = .done(response: updatedConversations ?? [])
        }
    }

    func setIsConversationFavorite(conversationId: Int64, isFavorite: Bool) async {
        isLoading = true
        let result = await messagesService.updateIsConversationFavorite(for: courseId, and: conversationId, isFavorite: isFavorite)
        switch result {
        case .notStarted, .loading:
            isLoading = false
        case .success:
            NotificationCenter.default.post(name: .favoriteConversationChanged,
                                            object: nil,
                                            userInfo: [conversationId: isFavorite])
            isLoading = false
        case .failure(let error):
            isLoading = false
            if let apiClientError = error as? APIClientError {
                presentError(userFacingError: UserFacingError(error: apiClientError))
            } else {
                presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            }
        }
    }

    func setIsConversationMuted(conversationId: Int64, isMuted: Bool) async {
        isLoading = true
        let result = await messagesService.updateIsConversationMuted(for: courseId, and: conversationId, isMuted: isMuted)
        switch result {
        case .notStarted, .loading:
            isLoading = false
        case .success:
            await loadConversations()
            isLoading = false
        case .failure(let error):
            isLoading = false
            if let error = error as? APIClientError {
                presentError(userFacingError: UserFacingError(error: error))
            } else {
                presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            }
        }
    }

    func setConversationIsHidden(conversationId: Int64, isHidden: Bool) async {
        isLoading = true
        let result = await messagesService.updateIsConversationHidden(for: courseId, and: conversationId, isHidden: isHidden)
        switch result {
        case .notStarted, .loading:
            isLoading = false
        case .success:
            await loadConversations()
            isLoading = false
        case .failure(let error):
            isLoading = false
            if let apiClientError = error as? APIClientError {
                presentError(userFacingError: UserFacingError(error: apiClientError))
            } else {
                presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            }
        }
    }
}

// MARK: Functions to handle new conversation received socket

private extension MessagesAvailableViewModel {
    func onConversationMembershipMessageReceived(conversationWebsocketDTO: ConversationWebsocketDTO) {
        switch conversationWebsocketDTO.action {
        case .create, .update:
            handleUpdateOrCreate(updatedOrNewConversation: conversationWebsocketDTO.conversation)
        case .delete:
            handleDelete(deletedConversation: conversationWebsocketDTO.conversation)
        case .newMessage:
            handleNewMessage(conversationWithNewMessage: conversationWebsocketDTO.conversation)
        }
    }

    func onNewSocketMessageReceived(messageWebsocketDTO: MessageWebsocketDTO) {
        if case .create = messageWebsocketDTO.action,
           let conversation = messageWebsocketDTO.post.conversation {
            handleNewMessage(conversationWithNewMessage: conversation)
        }
    }

    func handleUpdateOrCreate(updatedOrNewConversation: Conversation) {
        guard var conversations = allConversations.value else {
            // conversations not loaded yet
            return
        }
        if let conversationIndex = conversations.firstIndex(where: { $0.id == updatedOrNewConversation.id }) {
            // conversation is already cached -> update it
            conversations[conversationIndex] = updatedOrNewConversation
        } else {
            // conversation is not yet cached -> add it
            conversations.append(updatedOrNewConversation)
        }

        allConversations = .done(response: conversations)
    }

    func handleDelete(deletedConversation: Conversation) {
        guard var conversations = allConversations.value else {
            // conversations not loaded yet
            return
        }
        conversations.removeAll(where: { $0.id == deletedConversation.id })
        allConversations = .done(response: conversations)
    }

    func handleNewMessage(conversationWithNewMessage: Conversation) {
        guard var conversations = allConversations.value else {
            // conversations not loaded yet
            return
        }
        guard let conversationIndex = conversations.firstIndex(where: { $0.id == conversationWithNewMessage.id }) else {
            return
        }

        var conversation = conversations[conversationIndex].baseConversation

        conversation.lastMessageDate = conversationWithNewMessage.baseConversation.lastMessageDate
        conversation.unreadMessagesCount = (conversation.unreadMessagesCount ?? 0) + 1

        guard let updatedConversation = Conversation(conversation: conversation) else {
            log.error("Error adding new message to conversation")
            return
        }

        conversations[conversationIndex] = updatedConversation

        allConversations = .done(response: conversations)
    }
}

// MARK: Reload Notification

extension Foundation.Notification.Name {
    // Sending a notification of this type causes the Notification List to be reloaded,
    // when favorites are changed from elsewhere.
    static let favoriteConversationChanged = Foundation.Notification.Name("FavoriteConversationChanged")
}
