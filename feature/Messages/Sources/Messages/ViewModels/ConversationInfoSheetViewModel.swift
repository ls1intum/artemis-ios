//
//  File.swift
//  
//
//  Created by Sven Andabaka on 23.04.23.
//

import Foundation
import Common
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
                return .failure(error: UserFacingError(title: "Conversation could not be reloaded."))
            }
            return .done(response: conversation)
        }
    }

    func removeMemberFromConversation(for courseId: Int, conversationId: Int64, member: ConversationUser) async {
        print("TODO")
    }

    func leaveConversation(for courseId: Int, conversationId: Int64) async {
        print("TODO")
    }

    func deleteChannel(for courseId: Int, conversationId: Int64) async {
        print("TODO")
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
}
