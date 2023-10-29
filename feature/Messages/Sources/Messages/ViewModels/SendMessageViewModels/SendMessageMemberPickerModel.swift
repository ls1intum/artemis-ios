//
//  SendMessageMemberPickerModel.swift
//
//
//  Created by Nityananda Zbil on 28.10.23.
//

import Common
import SharedModels
import SwiftUI

class SendMessageMemberPickerModel: BaseViewModel {

    #warning("Leaky abstraction")
    static let paginationSize = 20

    let course: Course
    let conversation: Conversation

    var page = 0

    @Published var conversationMembers: [ConversationUser] = []
    @Published var paginationState: DataState<[ConversationUser]> = .loading

    var isMoreDataAvailable: Bool {
        let numberOfMembers = (conversation.baseConversation.numberOfMembers ?? 0)
        let isMoreDataAvailable = numberOfMembers > page * Self.paginationSize
        return isMoreDataAvailable
    }

    init(course: Course, conversation: Conversation) {
        self.course = course
        self.conversation = conversation
    }

    func loadMoreItems() async {
        isLoading = true
        paginationState = await MessagesServiceFactory.shared.getMembersOfConversation(
            for: course.id, conversationId: conversation.id, page: page)
        paginationState.value.map { more in
            conversationMembers += more
            page += 1
        }
        paginationState = .loading
        isLoading = false
    }
}
