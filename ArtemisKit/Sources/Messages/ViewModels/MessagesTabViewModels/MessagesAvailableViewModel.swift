//
//  MessagesTabViewModel.swift
//
//
//  Created by Sven Andabaka on 03.04.23.
//

import Foundation
import Common
import SharedModels
import SwiftUI
import APIClient
import UserStore

@MainActor
class MessagesAvailableViewModel: BaseViewModel {

    @Published var allConversations: DataState<[Conversation]> = .loading {
        didSet {
            updateFilteredConversations()
        }
    }

    @Published var filter: ConversationFilter = .all {
        didSet {
            withAnimation {
                updateFilteredConversations()
            }
        }
    }

    @Published var favoriteConversations: DataState<[Conversation]> = .loading

    @Published var channels: DataState<[Channel]> = .loading
    @Published var exercises: DataState<[Channel]> = .loading
    @Published var lectures: DataState<[Channel]> = .loading
    @Published var exams: DataState<[Channel]> = .loading
    @Published var groupChats: DataState<[GroupChat]> = .loading
    @Published var oneToOneChats: DataState<[OneToOneChat]> = .loading

    @Published var hiddenConversations: DataState<[Conversation]> = .loading

    var isDirectMessagingEnabled: Bool {
        course.courseInformationSharingConfiguration == .communicationAndMessaging
    }

    let course: Course
    let courseId: Int

    private let messagesService: MessagesService
    private let stompClient: ArtemisStompClient
    private let userSession: UserSession

    init(
        course: Course,
        messagesService: MessagesService = MessagesServiceFactory.shared,
        stompClient: ArtemisStompClient = ArtemisStompClient.shared,
        userSession: UserSession = UserSessionFactory.shared
    ) {
        self.course = course
        self.courseId = course.id

        self.messagesService = messagesService
        self.stompClient = stompClient
        self.userSession = userSession

        super.init()
    }

    func subscribeToConversationMembershipTopic() async {
        guard let userId = userSession.user?.id else {
            log.debug("User could not be found. Subscribe to Conversation not possible")
            return
        }

        let topic = WebSocketTopic.makeConversationMembershipNotifications(courseId: courseId, userId: userId)
        let stream = stompClient.subscribe(to: topic)

        for await message in stream {
            guard let conversationWebsocketDTO = JSONDecoder.getTypeFromSocketMessage(type: ConversationWebsocketDTO.self, message: message) else {
                continue
            }
            onConversationMembershipMessageReceived(conversationWebsocketDTO: conversationWebsocketDTO)
        }
    }

    func loadConversations() async {
        let result = await messagesService.getConversations(for: courseId)
        allConversations = result
    }

    func setIsConversationFavorite(conversationId: Int64, isFavorite: Bool) async {
        isLoading = true
        let result = await messagesService.updateIsConversationFavorite(for: courseId, and: conversationId, isFavorite: isFavorite)
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

    private func updateFilteredConversations() {
        switch allConversations {
        case .loading:
            favoriteConversations = .loading

            hiddenConversations = .loading

            channels = .loading
            exercises = .loading
            lectures = .loading
            exams = .loading
            groupChats = .loading
            oneToOneChats = .loading
        case .failure(let error):
            favoriteConversations = .failure(error: error)

            hiddenConversations = .failure(error: error)

            channels = .failure(error: error)
            exercises = .failure(error: error)
            lectures = .failure(error: error)
            exams = .failure(error: error)
            groupChats = .failure(error: error)
            oneToOneChats = .failure(error: error)
        case .done(let response):
            let notHiddenConversations = response.filter {
                !($0.baseConversation.isHidden ?? false)
            }

            favoriteConversations = .done(response: notHiddenConversations
                .filter { $0.baseConversation.isFavorite ?? false && filter.matches($0.baseConversation) }
            )

            // If we only show favorites, we can skip all other filtering
            if filter == .favorite {
                channels = .done(response: [])
                exercises = .done(response: [])
                lectures = .done(response: [])
                exams = .done(response: [])
                groupChats = .done(response: [])
                oneToOneChats = .done(response: [])
                hiddenConversations = .done(response: [])
                return
            }

            let notHiddenNotFavoriteConversations = notHiddenConversations.filter {
                !($0.baseConversation.isFavorite ?? false)
            }

            channels = .done(response: notHiddenNotFavoriteConversations
                .compactMap { $0.baseConversation as? Channel }
                .filter { ($0.subType ?? .general) == .general && filter.matches($0) }
            )
            exercises = .done(response: notHiddenNotFavoriteConversations
                .compactMap { $0.baseConversation as? Channel }
                .filter { ($0.subType ?? .general) == .exercise && filter.matches($0) }
            )
            lectures = .done(response: notHiddenNotFavoriteConversations
                .compactMap { $0.baseConversation as? Channel }
                .filter { ($0.subType ?? .general) == .lecture && filter.matches($0) }
            )
            exams = .done(response: notHiddenNotFavoriteConversations
                .compactMap { $0.baseConversation as? Channel }
                .filter { ($0.subType ?? .general) == .exam && filter.matches($0) }
            )
            groupChats = .done(response: notHiddenNotFavoriteConversations
                .compactMap { $0.baseConversation as? GroupChat }
                .filter { filter.matches($0) }
            )
            oneToOneChats = .done(response: notHiddenNotFavoriteConversations
                .compactMap { $0.baseConversation as? OneToOneChat }
                .filter { filter.matches($0) }
            )
            hiddenConversations = .done(response: response
                .filter { $0.baseConversation.isHidden ?? false && filter.matches($0.baseConversation) }
            )
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

enum ConversationFilter: FilterPicker {

    case all, unread, favorite

    var displayName: String {
        return switch self {
        case .all:
            R.string.localizable.allFilter()
        case .unread:
            R.string.localizable.unreadFilter()
        case .favorite:
            R.string.localizable.favoritesSection()
        }
    }

    var iconName: String {
        return switch self {
        case .all:
            "eye"
        case .unread:
            "app.badge"
        case .favorite:
            "heart"
        }
    }

    var selectedColor: Color {
        return switch self {
        case .all:
            Color.blue
        case .unread:
            Color.purple
        case .favorite:
            Color.orange
        }
    }

    var id: Int {
        hashValue
    }

    func matches(_ conversation: BaseConversation) -> Bool {
        switch self {
        case .all:
            true
        case .unread:
            conversation.unreadMessagesCount ?? 0 > 0
        case .favorite:
            conversation.isFavorite ?? false
        }
    }
}
