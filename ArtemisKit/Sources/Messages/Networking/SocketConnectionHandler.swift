//
//  SocketConnectionHandler.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 15.11.24.
//

import APIClient
import Combine
import Foundation

class SocketConnectionHandler {
    private let stompClient = ArtemisStompClient.shared
    let messagePublisher = PassthroughSubject<MessageWebsocketDTO, Never>()
    let conversationPublisher = PassthroughSubject<ConversationWebsocketDTO, Never>()

    private var channelSubscription: Task<(), Never>?
    private var conversationSubscription: Task<(), Never>?
    private var membershipSubscription: Task<(), Never>?

    static let shared = SocketConnectionHandler()

    private init() {}

    func cancelSubscriptions() {
        channelSubscription?.cancel()
        conversationSubscription?.cancel()
        membershipSubscription?.cancel()

        channelSubscription = nil
        conversationSubscription = nil
        membershipSubscription = nil
    }

    func subscribeToChannelNotifications(courseId: Int) {
        guard channelSubscription == nil else {
            return
        }

        let topic = WebSocketTopic.makeChannelNotifications(courseId: courseId)

        channelSubscription = Task { [weak self] in
            guard let self else {
                return
            }

            let stream = stompClient.subscribe(to: topic)

            for await message in stream {
                guard let messageWebsocketDTO = JSONDecoder.getTypeFromSocketMessage(type: MessageWebsocketDTO.self, message: message) else {
                    continue
                }
                print("Stomp channel")

                messagePublisher.send(messageWebsocketDTO)
            }
        }
    }

    func subscribeToConversationNotifications(userId: Int64) {
        guard conversationSubscription == nil else {
            return
        }

        let topic = WebSocketTopic.makeConversationNotifications(userId: userId)

        conversationSubscription = Task { [weak self] in
            guard let self else {
                return
            }

            let stream = stompClient.subscribe(to: topic)

            for await message in stream {
                guard let messageWebsocketDTO = JSONDecoder.getTypeFromSocketMessage(type: MessageWebsocketDTO.self, message: message) else {
                    continue
                }
                print("Stomp convo")
                messagePublisher.send(messageWebsocketDTO)
            }
        }
    }

    func subscribeToMembershipNotifications(courseId: Int, userId: Int64) {
        guard membershipSubscription == nil else {
            return
        }

        let topic = WebSocketTopic.makeConversationMembershipNotifications(courseId: courseId, userId: userId)
        membershipSubscription = Task { [weak self] in
            guard let self else {
                return
            }

            let stream = stompClient.subscribe(to: topic)

            for await message in stream {
                guard let conversationWebsocketDTO = JSONDecoder.getTypeFromSocketMessage(type: ConversationWebsocketDTO.self, message: message) else {
                    continue
                }
                conversationPublisher.send(conversationWebsocketDTO)
            }
        }
    }
}
