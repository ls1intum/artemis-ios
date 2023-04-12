//
//  ConversationViewModel.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

import Foundation
import Common
import SharedModels
import APIClient

@MainActor
public class ConversationViewModel: BaseViewModel {

    @Published var dailyMessages: DataState<[Date: [Message]]> = .loading
    @Published var conversation: DataState<Conversation> = .loading

    let courseId: Int
    let conversationId: Int64

    private var size = 50

    public init(courseId: Int, conversation: Conversation) {
        self.courseId = courseId
        self._conversation = Published(wrappedValue: .done(response: conversation))
        self.conversationId = conversation.id

        super.init()
    }

    public init(courseId: Int, conversationId: Int64) {
        self.courseId = courseId
        self.conversationId = conversationId
        self._conversation = Published(wrappedValue: .loading)

        super.init()

        Task {
            await loadConversation()
        }
    }

    func loadFurtherMessages() async {
        size += 50
        await loadMessages()
    }

    func loadMessages() async {
        let result = await MessagesServiceFactory.shared.getMessages(for: courseId, and: conversationId, size: size)

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

    func sendMessage(text: String) async -> NetworkResponse {
        guard let conversation = conversation.value else {
            let error = UserFacingError(title: "Conversation could not be loaded.")
            presentError(userFacingError: error)
            return .failure(error: error)
        }
        isLoading = true
        let result = await MessagesServiceFactory.shared.sendMessage(for: courseId, conversation: conversation, content: text)
        switch result {
        case .notStarted, .loading:
            isLoading = false
        case .success:
            await loadMessages()
            isLoading = false
        case .failure(let error):
            isLoading = false
            if let apiClientError = error as? APIClientError {
                presentError(userFacingError: UserFacingError(error: apiClientError))
            } else {
                presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            }
        }
        return result
    }

    private func loadConversation() async {
        let result = await MessagesServiceFactory.shared.getConversations(for: courseId)

        switch result {
        case .loading:
            conversation = .loading
        case .failure(let error):
            conversation = .failure(error: error)
        case .done(let response):
            guard let conversation = response.first(where: { $0.id == conversationId }) else {
                self.conversation = .failure(error: UserFacingError(title: "The conversation could not be found."))
                return
            }
            self.conversation = .done(response: conversation)
        }
    }
}
