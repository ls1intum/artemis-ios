//
//  MessagesTabViewModel.swift
//  
//
//  Created by Sven Andabaka on 03.04.23.
//

import Foundation
import Common
import SharedModels
import APIClient
import UserStore

@MainActor
class MessagesTabViewModel: BaseViewModel {

    @Published var allConversations: DataState<[Conversation]> = .loading {
        didSet {
            updateFilteredConversations()
        }
    }

    @Published var favoriteConversations: DataState<[Conversation]> = .loading

    @Published var hiddenConversations: DataState<[Conversation]> = .loading

    @Published var isCodeOfConductAccepted: DataState<Bool> = .loading

    @Published var channels: DataState<[Channel]> = .loading
    @Published var exercises: DataState<[Channel]> = .loading
    @Published var lectures: DataState<[Channel]> = .loading
    @Published var exams: DataState<[Channel]> = .loading
    @Published var groupChats: DataState<[GroupChat]> = .loading
    @Published var oneToOneChats: DataState<[OneToOneChat]> = .loading

    let courseId: Int
    let course: Course

    init(course: Course) {
        self.courseId = course.id
        self.course = course

        super.init()
    }

    func subscribeToConversationMembershipTopic() async {
        guard let userId = UserSession.shared.user?.id else {
            log.debug("User could not be found. Subscribe to Conversation not possible")
            return
        }

        let topic = "/user/topic/metis/courses/\(courseId)/conversations/user/\(userId)"
        let stream = ArtemisStompClient.shared.subscribe(to: topic)

        for await message in stream {
            guard let conversationWebsocketDTO = JSONDecoder.getTypeFromSocketMessage(type: ConversationWebsocketDTO.self, message: message) else { continue }
            onConversationMembershipMessageReceived(conversationWebsocketDTO: conversationWebsocketDTO)
        }
    }

    func loadConversations() async {
        let result = await MessagesServiceFactory.shared.getConversations(for: courseId)
        allConversations = result
    }

    func hideUnhideConversation(conversationId: Int64, isHidden: Bool) async {
        isLoading = true
        let result = await MessagesServiceFactory.shared.hideUnhideConversation(for: courseId, and: conversationId, isHidden: isHidden)
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

    func setIsFavoriteConversation(conversationId: Int64, isFavorite: Bool) async {
        isLoading = true
        let result = await MessagesServiceFactory.shared.setIsFavoriteConversation(for: courseId, and: conversationId, isFavorite: isFavorite)
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

    func isCodeOfConductAccepted() async {
        isLoading = true
        isCodeOfConductAccepted = await MessagesServiceFactory.shared.getIsCodeOfConductAccepted(for: courseId)
        isLoading = false
    }

    func acceptCodeOfConduct() async {
        isLoading = true
        let result = await MessagesServiceFactory.shared.acceptCodeOfConduct(for: courseId)
        switch result {
        case .notStarted, .loading:
            isLoading = false
        case .success:
            isCodeOfConductAccepted = .done(response: true)
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
            hiddenConversations = .done(response: response.filter { $0.baseConversation.isHidden ?? false })

            let notHiddenConversations = response.filter { !($0.baseConversation.isHidden ?? false) }

            favoriteConversations = .done(response: notHiddenConversations.filter { $0.baseConversation.isFavorite ?? false })

            let notHiddenNotFavoriteConversations = notHiddenConversations.filter { !($0.baseConversation.isFavorite ?? false) }

            channels = .done(response: notHiddenNotFavoriteConversations.compactMap({ $0.baseConversation as? Channel }).filter({ ($0.subType ?? .general) == .general }))
            exercises = .done(response: notHiddenNotFavoriteConversations.compactMap({ $0.baseConversation as? Channel }).filter({ ($0.subType ?? .general) == .exercise }))
            lectures = .done(response: notHiddenNotFavoriteConversations.compactMap({ $0.baseConversation as? Channel }).filter({ ($0.subType ?? .general) == .lecture }))
            exams = .done(response: notHiddenNotFavoriteConversations.compactMap({ $0.baseConversation as? Channel }).filter({ ($0.subType ?? .general) == .exam }))
            groupChats = .done(response: notHiddenNotFavoriteConversations.compactMap({ $0.baseConversation as? GroupChat }))
            oneToOneChats = .done(response: notHiddenNotFavoriteConversations.compactMap({ $0.baseConversation as? OneToOneChat }))
        }
    }
}

// All functions to handle new conversation received socket
extension MessagesTabViewModel {
    private func onConversationMembershipMessageReceived(conversationWebsocketDTO: ConversationWebsocketDTO) {
        switch conversationWebsocketDTO.metisCrudAction {
        case .create, .update:
            handleUpdateOrCreate(updatedOrNewConversation: conversationWebsocketDTO.conversation)
        case .delete:
            handleDelete(deletedConversation: conversationWebsocketDTO.conversation)
        case .newMessage:
            handleNewMessage(conversationWithNewMessage: conversationWebsocketDTO.conversation)
        }
    }

    private func handleUpdateOrCreate(updatedOrNewConversation: Conversation) {
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

    private func handleDelete(deletedConversation: Conversation) {
        guard var conversations = allConversations.value else {
            // conversations not loaded yet
            return
        }
        conversations.removeAll(where: { $0.id == deletedConversation.id })
        allConversations = .done(response: conversations)
    }

    private func handleNewMessage(conversationWithNewMessage: Conversation) {
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
