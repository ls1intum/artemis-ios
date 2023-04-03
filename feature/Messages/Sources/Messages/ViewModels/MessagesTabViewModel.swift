//
//  MessagesTabViewModel.swift
//  
//
//  Created by Sven Andabaka on 03.04.23.
//

import Foundation
import Common

@MainActor
class MessagesTabViewModel: ObservableObject {

    @Published var channels: DataState<[Conversation]> = .loading
    @Published var groupChats: DataState<[Conversation]> = .loading
    @Published var oneToOneChats: DataState<[Conversation]> = .loading

    private let courseId: Int

    init(courseId: Int) {
        self.courseId = courseId
    }

    func loadConversations() async {
        let result = await MessagesServiceFactory.shared.getConversations(for: courseId)
        handleResult(result: result, by: .channel)
        handleResult(result: result, by: .groupChat)
        handleResult(result: result, by: .oneToOneChat)
    }

    private func handleResult(result: DataState<[Conversation]>, by conversationType: ConversationType) {
        var filteredResult: DataState<[Conversation]>

        switch result {
        case .loading:
            filteredResult = .loading
        case .failure(let error):
            filteredResult = .failure(error: error)
        case .done(let response):
            filteredResult = .done(response: response.filter { $0.type == conversationType })
        }

        switch conversationType {
        case .oneToOneChat:
            oneToOneChats = filteredResult
        case .groupChat:
            groupChats = filteredResult
        case .channel:
            channels = filteredResult
        }
    }
}
