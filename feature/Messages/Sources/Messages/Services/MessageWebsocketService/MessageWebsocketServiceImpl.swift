//
//  File.swift
//  
//
//  Created by Sven Andabaka on 11.05.23.
//

import Foundation
import SharedModels
import APIClient
import UserStore
import Common

class MessageWebsocketServiceImpl: MessageWebsocketService {

    private var continuation: AsyncStream<Message>.Continuation?
    private var stream: AsyncStream<Message>?

    private var subscribedTopics: [String] = []
    private var tasks: [Task<(), Never>] = []

    static let shared = MessageWebsocketServiceImpl()

    let queue = DispatchQueue(label: "thread-safe-websocket-message")

    private init() { }

    func subscribeToConversationMembershipTopicStream(for courseId: Int) -> AsyncStream<Message> {
        if let stream {
            return stream
        }

        let stream = AsyncStream<Message> { continuation in
            continuation.onTermination = { [weak self] _ in
                self?.queue.async { [weak self] in
                    self?.tasks.forEach { $0.cancel() }
                    self?.continuation = nil
                    self?.subscribedTopics = []
                    self?.stream = nil
                }
            }

            self.continuation = continuation
        }

        self.stream = stream

        subscribeToConversationMembershipTopic(for: courseId)

        return stream
    }

    private func subscribeToConversationMembershipTopic(for courseId: Int) {
        guard let userId = UserSession.shared.user?.id else {
            log.debug("User could not be found. Subscribe to Conversation not possible")
            return
        }

        let topic = "/user/topic/metis/courses/\(courseId)/conversations/user/\(userId)"
        let stream = subscribe(to: topic)

        let task = Task {
            for await message in stream {
                guard let message = JSONDecoder.getTypeFromSocketMessage(type: ConversationWebsocketDTO.self, message: message) else { continue }

                print(message)
            }
        }
        addTask(task)
    }

    private func subscribe(to topic: String) -> AsyncStream<Any?> {
        queue.async { [weak self] in
            self?.subscribedTopics.append(topic)
        }
        return ArtemisStompClient.shared.subscribe(to: topic)
    }

    private func addTask(_ task: Task<(), Never>) {
        queue.async { [weak self] in
            self?.tasks.append(task)
        }
    }
}
