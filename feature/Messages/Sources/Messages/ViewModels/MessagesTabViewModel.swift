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

    @Published var favoriteConversations: DataState<[Conversation]> = .loading

    @Published var hiddenConversations: DataState<[Conversation]> = .loading

    @Published var channels: DataState<[Channel]> = .loading
    @Published var groupChats: DataState<[GroupChat]> = .loading
    @Published var oneToOneChats: DataState<[OneToOneChat]> = .loading

    let courseId: Int

    init(courseId: Int) {
        self.courseId = courseId
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

            channels = .done(response: notHiddenConversations.compactMap({ $0.baseConversation as? Channel }))
            groupChats = .done(response: notHiddenConversations.compactMap({ $0.baseConversation as? GroupChat }))
            oneToOneChats = .done(response: notHiddenConversations.compactMap({ $0.baseConversation as? OneToOneChat }))
        }
    }
}
