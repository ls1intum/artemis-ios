//
//  File.swift
//  
//
//  Created by Sven Andabaka on 23.04.23.
//

import Foundation
import Common
import UserStore
import SharedModels

class ConversationInfoSheetViewModel: BaseViewModel {

    @Published var members: DataState<[ConversationUser]> = .loading

    @Published var page = 0

    func loadMembers(for courseId: Int, conversationId: Int64) async {
        members = await MessagesServiceFactory.shared.getMembersOfConversation(for: courseId, conversationId: conversationId, page: page)
    }

    func loadNextMemberPage(for courseId: Int, conversationId: Int64) async {
        page += 1
        await loadMembers(for: courseId, conversationId: conversationId)
    }

    func loadPreviousMemberPage(for courseId: Int, conversationId: Int64) async {
        page -= 1
        await loadMembers(for: courseId, conversationId: conversationId)
    }

    func reloadConversation(for courseId: Int, conversationId: Int64) async -> DataState<Conversation> {
        // TODO: replace by call for single specific conversation
        let result = await MessagesServiceFactory.shared.getConversations(for: courseId)

        switch result {
        case .loading:
            return .loading
        case .failure(let error):
            return .failure(error: error)
        case .done(let response):
            guard let conversation = response.first(where: { $0.id == conversationId }) else {
                return .failure(error: UserFacingError(title: R.string.localizable.conversationNotLoaded()))
            }
            return .done(response: conversation)
        }
    }

    func removeMemberFromConversation(for courseId: Int, conversation: Conversation, member: ConversationUser) async -> DataState<Conversation> {
        guard let username = member.login else { return .failure(error: UserFacingError(title: R.string.localizable.cantRemoveMembers())) }

        let result: NetworkResponse
        switch conversation {
        case .channel(let conversation):
            result = await MessagesServiceFactory.shared.removeMembersFromChannel(for: courseId, channelId: conversation.id, usernames: [username])
        case .groupChat(let conversation):
            result = await MessagesServiceFactory.shared.removeMembersFromGroupChat(for: courseId, groupChatId: conversation.id, usernames: [username])
        case .oneToOneChat, .unknown:
            // do nothing
            return .failure(error: UserFacingError(title: R.string.localizable.conversationNotLoaded()))
        }

        switch result {
        case .notStarted, .loading:
            return .loading
        case .success:
            await loadMembers(for: courseId, conversationId: conversation.id)
            return await reloadConversation(for: courseId, conversationId: conversation.id)
        case .failure(let error):
            presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            return .failure(error: UserFacingError(title: error.localizedDescription))
        }
    }

    func leaveConversation(for courseId: Int, conversation: Conversation) async -> Bool {
        let result: NetworkResponse
        switch conversation {
        case .channel(let conversation):
            result = await MessagesServiceFactory.shared.leaveChannel(for: courseId, channelId: conversation.id)
        case .groupChat(let conversation):
            result = await MessagesServiceFactory.shared.leaveConversation(for: courseId, groupChatId: conversation.id)
        case .oneToOneChat, .unknown:
            // do nothing
            return false
        }

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

    func archiveChannel(for courseId: Int, conversationId: Int64) async -> DataState<Conversation> {
        let result = await MessagesServiceFactory.shared.archiveChannel(for: courseId, channelId: conversationId)

        switch result {
        case .notStarted, .loading:
            // do nothing
            return .loading
        case .success:
            return await reloadConversation(for: courseId, conversationId: conversationId)
        case .failure(let error):
            presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            return .failure(error: UserFacingError(title: error.localizedDescription))
        }
    }

    func unarchiveChannel(for courseId: Int, conversationId: Int64) async -> DataState<Conversation> {
        let result = await MessagesServiceFactory.shared.unarchiveChannel(for: courseId, channelId: conversationId)

        switch result {
        case .notStarted, .loading:
            // do nothing
            return .loading
        case .success:
            return await reloadConversation(for: courseId, conversationId: conversationId)
        case .failure(let error):
            presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            return .failure(error: UserFacingError(title: error.localizedDescription))
        }
    }

    func editName(for courseId: Int, conversation: Conversation, newName: String) async -> DataState<Conversation> {
        let result = await MessagesServiceFactory.shared.editConversation(for: courseId, conversation: conversation, newName: newName)
        isLoading = false
        return result
    }

    func editTopic(for courseId: Int, conversation: Conversation, newTopic: String) async -> DataState<Conversation> {
        let result = await MessagesServiceFactory.shared.editConversation(for: courseId, conversation: conversation, newTopic: newTopic)
        isLoading = false
        return result
    }

    func editDescription(for courseId: Int, conversation: Conversation, newDescription: String) async -> DataState<Conversation> {
        let result = await MessagesServiceFactory.shared.editConversation(for: courseId, conversation: conversation, newDescription: newDescription)
        isLoading = false
        return result
    }
}
