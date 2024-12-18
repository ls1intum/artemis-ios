//
//  ConversationListViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.12.24.
//

import Foundation
import SharedModels

@Observable
@MainActor
class ConversationListViewModel {
    let parentViewModel: MessagesAvailableViewModel

    var filter: ConversationFilter = .all

    var conversations: [Conversation]
    var favoriteConversations = [Conversation]()

    var channels = [Channel]()
    var exercises = [Channel]()
    var lectures = [Channel]()
    var exams = [Channel]()
    var groupChats = [GroupChat]()
    var oneToOneChats = [OneToOneChat]()

    var hiddenConversations = [Conversation]()

    init(parentViewModel: MessagesAvailableViewModel, conversations: [Conversation]) {
        self.parentViewModel = parentViewModel
        self.conversations = conversations
        updateConversations()
    }

    func updateConversations() {
        let course = parentViewModel.course

        let notHiddenConversations = conversations.filter {
            !($0.baseConversation.isHidden ?? false)
        }

        // Turn off filter if no unread/favorites exist
        if !conversations.contains(where: { conversation in
            conversation.baseConversation.unreadMessagesCount ?? 0 > 0
        }) && !notHiddenConversations.contains(where: { conversation in
            conversation.baseConversation.isFavorite ?? false
        }) && filter != .all {
            filter = .all
        }

        favoriteConversations = notHiddenConversations
            .filter {
                $0.baseConversation.isFavorite ?? false && filter.matches($0.baseConversation, course: course)
            }

        channels = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .general && filter.matches($0, course: course) }

        exercises = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .exercise && filter.matches($0, course: course) }

        lectures = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .lecture && filter.matches($0, course: course) }

        exams = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .exam && filter.matches($0, course: course) }

        groupChats = notHiddenConversations
            .compactMap { $0.baseConversation as? GroupChat }
            .filter { filter.matches($0, course: course) }

        oneToOneChats = notHiddenConversations
            .compactMap { $0.baseConversation as? OneToOneChat }
            .filter { filter.matches($0, course: course) }

        hiddenConversations = conversations
            .filter { $0.baseConversation.isHidden ?? false && filter.matches($0.baseConversation, course: course) }
    }
}
