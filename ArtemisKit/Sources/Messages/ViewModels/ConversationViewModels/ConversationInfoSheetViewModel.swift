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
import SwiftUI

@MainActor
class ConversationInfoSheetViewModel: BaseViewModel {
    let course: Course

    private let _conversation: Binding<Conversation>
    var conversation: Conversation {
        get {
            _conversation.wrappedValue
        }
        set {
            _conversation.wrappedValue = newValue
        }
    }

    @Published var isAddMemberSheetPresented = false
    @Published var members: DataState<[ConversationUser]> = .loading
    @Published var page = 0

    private let messagesService: MessagesService

    init(course: Course, conversation: Binding<Conversation>, messagesService: MessagesService = MessagesServiceFactory.shared) {
        self.course = course
        self._conversation = conversation
        self.messagesService = messagesService
    }
}

extension ConversationInfoSheetViewModel {
    var canLeaveConversation: Bool {
        // not possible to leave a conversation as not a member
        if !(conversation.baseConversation.isMember ?? false) {
            return false
        }
        // the creator of a channel can not leave it
        if conversation.baseConversation is Channel && conversation.baseConversation.isCreator ?? false {
            return false
        }
        // can not leave a oneToOne chat
        if conversation.baseConversation is OneToOneChat {
            return false
        }
        return true
    }

    var canAddUsers: Bool {
        switch conversation {
        case .channel(let conversation):
            return conversation.hasChannelModerationRights ?? false
        case .groupChat(let conversation):
            return conversation.isMember ?? false
        case .oneToOneChat:
            return false
        case .unknown:
            return false
        }
    }

    var canRemoveUsers: Bool {
        canAddUsers
    }
}

extension ConversationInfoSheetViewModel {
    func refreshConversation() async {
        // TODO: replace by call for single specific conversation
        let result = await messagesService.getConversations(for: course.id)

        let state: DataState<Conversation> = result.flatMap { conversations in
            guard let conversation = conversations.first(where: { $0.id == conversation.id }) else {
                return .failure(UserFacingError(title: R.string.localizable.conversationNotLoaded()))
            }
            return .success(conversation)
        }

        switch state {
        case .loading:
            break
        case let .failure(error):
            presentError(userFacingError: error)
        case let .done(response):
            conversation = response
        }
    }

    func loadMembers() async {
        members = await messagesService.getMembersOfConversation(for: course.id, conversationId: conversation.id, page: page)
    }

    func loadNextMemberPage() async {
        page += 1
        await loadMembers()
    }

    func loadPreviousMemberPage() async {
        page -= 1
        await loadMembers()
    }

    func removeMemberFromConversation(member: ConversationUser) async {
        guard let username = member.login else {
            presentError(userFacingError: UserFacingError(title: R.string.localizable.cantRemoveMembers()))
            return
        }

        let result: NetworkResponse
        switch conversation {
        case .channel(let conversation):
            result = await messagesService.removeMembersFromChannel(for: course.id, channelId: conversation.id, usernames: [username])
        case .groupChat(let conversation):
            result = await messagesService.removeMembersFromGroupChat(for: course.id, groupChatId: conversation.id, usernames: [username])
        case .oneToOneChat, .unknown:
            result = .failure(error: UserFacingError(title: R.string.localizable.conversationNotLoaded()))
        }

        switch result {
        case .notStarted, .loading:
            break
        case .success:
            await loadMembers()
            await refreshConversation()
        case .failure(let error):
            presentError(userFacingError: UserFacingError(title: error.localizedDescription))
        }
    }

    func leaveConversation() async -> Bool {
        let result: NetworkResponse
        switch conversation {
        case .channel(let conversation):
            result = await messagesService.leaveChannel(for: course.id, channelId: conversation.id)
        case .groupChat(let conversation):
            result = await messagesService.leaveConversation(for: course.id, groupChatId: conversation.id)
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

    func archiveChannel() async {
        let result = await messagesService.archiveChannel(for: course.id, channelId: conversation.id)

        switch result {
        case .notStarted, .loading:
            break
        case .success:
            await refreshConversation()
        case .failure(let error):
            presentError(userFacingError: UserFacingError(title: error.localizedDescription))
        }
    }

    func unarchiveChannel() async {
        let result = await messagesService.unarchiveChannel(for: course.id, channelId: conversation.id)

        switch result {
        case .notStarted, .loading:
            break
        case .success:
            await refreshConversation()
        case .failure(let error):
            presentError(userFacingError: UserFacingError(title: error.localizedDescription))
        }
    }

    func editName(newName: String) async {
        let result = await messagesService.editConversation(for: course.id, conversation: conversation, newName: newName)
        isLoading = false

        switch result {
        case .loading:
            break
        case .failure(let error):
            presentError(userFacingError: error)
        case .done(let response):
            conversation = response
        }
    }

    func editTopic(newTopic: String) async {
        let result = await messagesService.editConversation(for: course.id, conversation: conversation, newTopic: newTopic)
        isLoading = false

        switch result {
        case .loading:
            break
        case .failure(let error):
            presentError(userFacingError: error)
        case .done(let response):
            conversation = response
        }
    }

    func editDescription(newDescription: String) async {
        let result = await messagesService.editConversation(for: course.id, conversation: conversation, newDescription: newDescription)
        isLoading = false

        switch result {
        case .loading:
            break
        case .failure(let error):
            presentError(userFacingError: error)
        case .done(let response):
            conversation = response
        }
    }
}
