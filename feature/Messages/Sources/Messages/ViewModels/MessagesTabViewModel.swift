//
//  MessagesTabViewModel.swift
//  
//
//  Created by Sven Andabaka on 03.04.23.
//

import Foundation
import Common
import SharedModels

@MainActor
class MessagesTabViewModel: ObservableObject {

    @Published var allConversations: DataState<[Conversation]> = .loading

    @Published var channels: DataState<[Channel]> = .loading
    @Published var groupChats: DataState<[GroupChat]> = .loading
    @Published var oneToOneChats: DataState<[OneToOneChat]> = .loading

    @Published var hiddenChannels: DataState<[Channel]> = .loading
    @Published var hiddenGroupChats: DataState<[GroupChat]> = .loading
    @Published var hiddenOneToOneChats: DataState<[OneToOneChat]> = .loading

    let courseId: Int

    init(courseId: Int) {
        self.courseId = courseId
    }

    func loadConversations() async {
        let result = await MessagesServiceFactory.shared.getConversations(for: courseId)
        allConversations = result

        switch result {
        case .loading:
            channels = .loading
            groupChats = .loading
            oneToOneChats = .loading
            hiddenChannels = .loading
            hiddenGroupChats = .loading
            hiddenOneToOneChats = .loading
        case .failure(let error):
            hiddenChannels = .failure(error: error)
            hiddenGroupChats = .failure(error: error)
            hiddenOneToOneChats = .failure(error: error)
        case .done(let response):
            let hiddenConversations = response.filter { $0.baseConversation.isHidden ?? false }
            let notHiddenConversations = response.filter { !($0.baseConversation.isHidden ?? false) }

            channels = .done(response: notHiddenConversations.compactMap({ $0.baseConversation as? Channel }))
            hiddenChannels = .done(response: hiddenConversations.compactMap({ $0.baseConversation as? Channel }))

            groupChats = .done(response: notHiddenConversations.compactMap({ $0.baseConversation as? GroupChat }))
            hiddenGroupChats = .done(response: hiddenConversations.compactMap({ $0.baseConversation as? GroupChat }))

            oneToOneChats = .done(response: notHiddenConversations.compactMap({ $0.baseConversation as? OneToOneChat }))
            hiddenOneToOneChats = .done(response: hiddenConversations.compactMap({ $0.baseConversation as? OneToOneChat }))
        }
    }
}
