//
//  CreateChatViewModel.swift
//  
//
//  Created by Sven Andabaka on 23.04.23.
//

import Foundation
import Common
import SharedModels

class CreateChatViewModel: BaseViewModel {

    @Published var searchText = "" {
        didSet {
            if searchText.count > 2 {
                searchResults = .loading
                Task {
                    await loadUsers()
                }
            }
        }
    }
    @Published var searchResults: DataState<[ConversationUser]> = .done(response: [])

    @Published var selectedUsers: [ConversationUser] = []

    let courseId: Int

    init(courseId: Int) {
        self.courseId = courseId
    }

    func loadUsers() async {
        searchResults = await MessagesServiceFactory.shared.searchForUsers(for: courseId, searchText: searchText)
    }

    func createChat() async -> Int64? {
        let usernames = selectedUsers.compactMap { $0.login }

        if usernames.isEmpty {
            presentError(userFacingError: UserFacingError(title: R.string.localizable.selectAtLeastOneUser()))
            return nil
        }

        if usernames.count > 1 {
            let result = await MessagesServiceFactory.shared.createGroupChat(for: courseId, usernames: usernames)
            switch result {
            case .loading:
                return nil
            case .failure(let error):
                presentError(userFacingError: error)
                return nil
            case .done(let response):
                return response.id
            }
        } else {
            let result = await MessagesServiceFactory.shared.createOneToOneChat(for: courseId, usernames: usernames)
            switch result {
            case .loading:
                return nil
            case .failure(let error):
                presentError(userFacingError: error)
                return nil
            case .done(let response):
                return response.id
            }
        }
    }

    func addUsersToConversation(_ conversation: Conversation) async -> Bool {
        let usernames = selectedUsers.compactMap { $0.login }

        switch conversation {
        case .channel(let conversation):
            let result = await MessagesServiceFactory.shared.addMembersToChannel(for: courseId, channelId: conversation.id, usernames: usernames)
            switch result {
            case .loading, .notStarted:
                return false
            case .failure(let error):
                presentError(userFacingError: UserFacingError(title: error.localizedDescription))
                return false
            case .success:
                return true
            }
        case .groupChat(let conversation):
            let result = await MessagesServiceFactory.shared.addMembersToGroupChat(for: courseId, groupChatId: conversation.id, usernames: usernames)
            switch result {
            case .loading, .notStarted:
                return false
            case .failure(let error):
                presentError(userFacingError: UserFacingError(title: error.localizedDescription))
                return false
            case .success:
                return true
            }
        default:
            presentError(userFacingError: UserFacingError(title: R.string.localizable.cantAddUserToThisConversation()))
            return false
        }
    }
}
