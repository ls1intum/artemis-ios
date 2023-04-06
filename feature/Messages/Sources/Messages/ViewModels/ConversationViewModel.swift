//
//  ConversationViewModel.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

import Foundation
import Common
import SharedModels

@MainActor
class ConversationViewModel: ObservableObject {

    @Published var dailyMessages: DataState<[Date: [Message]]> = .loading

    let courseId: Int
    let conversation: Conversation

    init(courseId: Int, conversation: Conversation) {
        self.courseId = courseId
        self.conversation = conversation
    }

    func loadMessages() async {
        let result = await MessagesServiceFactory.shared.getMessages(for: courseId, and: conversation.id)

        switch result {
        case .loading:
            dailyMessages = .loading
        case .failure(let error):
            dailyMessages = .failure(error: error)
        case .done(let response):
            var dailyMessages: [Date: [Message]] = [:]

            response.forEach { message in
                if let date = message.creationDate?.startOfDay {
                    if dailyMessages[date] == nil {
                        dailyMessages[date] = [message]
                    } else {
                        dailyMessages[date]?.append(message)
                        dailyMessages[date] = dailyMessages[date]?.sorted(by: { $0.creationDate! < $1.creationDate! })
                    }
                }
            }

            self.dailyMessages = .done(response: dailyMessages)
        }
    }
}
