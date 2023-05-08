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

    @Published var allConversations: DataState<[Conversation]> = .loading

    @Published var favoriteConversations: DataState<[Conversation]> = .loading

    @Published var hiddenConversations: DataState<[Conversation]> = .loading

    @Published var channels: DataState<[Channel]> = .loading
    @Published var groupChats: DataState<[GroupChat]> = .loading
    @Published var oneToOneChats: DataState<[OneToOneChat]> = .loading

    let courseId: Int
    let course: Course

    init(course: Course) {
        self.courseId = course.id
        self.course = course

        super.init()

        ArtemisStompClient.shared.setup()
        testSubscribe()
    }

    private func testSubscribe() {
        guard let userId = UserSession.shared.user?.id else { return }

        let stream = ArtemisStompClient.shared.subscribe(to: "/user/topic/metis/courses/\(courseId)/conversations/user/\(userId)")

        Task {
            for await message in stream {
                log.debug(message)
                await loadConversations()
            }
        }
    }

    func loadConversations() async {
        let result = await MessagesServiceFactory.shared.getConversations(for: courseId)
        allConversations = result

        switch result {
        case .loading:
            favoriteConversations = .loading

            hiddenConversations = .loading

            channels = .loading
            groupChats = .loading
            oneToOneChats = .loading
        case .failure(let error):
            favoriteConversations = .failure(error: error)

            hiddenConversations = .failure(error: error)

            channels = .failure(error: error)
            groupChats = .failure(error: error)
            oneToOneChats = .failure(error: error)
        case .done(let response):
            hiddenConversations = .done(response: response.filter { $0.baseConversation.isHidden ?? false })

            let notHiddenConversations = response.filter { !($0.baseConversation.isHidden ?? false) }

            favoriteConversations = .done(response: notHiddenConversations.filter { $0.baseConversation.isFavorite ?? false })

            let notHiddenNotFavoriteConversations = notHiddenConversations.filter { !($0.baseConversation.isFavorite ?? false) }

            channels = .done(response: notHiddenNotFavoriteConversations.compactMap({ $0.baseConversation as? Channel }))
            groupChats = .done(response: notHiddenNotFavoriteConversations.compactMap({ $0.baseConversation as? GroupChat }))
            oneToOneChats = .done(response: notHiddenNotFavoriteConversations.compactMap({ $0.baseConversation as? OneToOneChat }))
        }
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
}
