//
//  IrisWebsocketServiceImpl.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 19.05.26.
//

import APIClient
import Common
import Foundation

/// Decodes Iris WebSocket payloads for a chat session into typed streams.
///
/// Multi-consumer: each ``subscribe(sessionId:)`` returns its own stream, all fed
/// by a single STOMP subscription per session (a "hub"). This tolerates the
/// overlapping view instances SwiftUI briefly creates for the same session during
/// a navigation/tab transition — they no longer cancel each other's subscription.
/// A consumer is dropped automatically when its stream is cancelled (the view's
/// `.task` ends); the hub's STOMP subscription is torn down, after a short debounce,
/// once its last consumer is gone.
actor IrisWebsocketServiceImpl: IrisWebsocketService {

    // Debounce window for tearing down a hub's STOMP subscription. ArtemisStompClient
    // disconnects the socket as soon as its topic list is empty, so a fast
    // chat-to-chat navigation (last consumer leaves, new one joins) would otherwise
    // race the reconnect and surface a network error. Holding the topic for a short
    // grace period keeps the socket alive across the swap.
    private static let unsubscribeDebounce: Duration = .milliseconds(300)

    private struct SessionHub {
        /// The single STOMP reader fanning out to all consumers of this session.
        let task: Task<Void, Never>
        /// Live consumers keyed by an opaque token, each with its own stream.
        var consumers: [Int: AsyncStream<IrisChatWebsocketDTO>.Continuation] = [:]
    }

    private var hubs: [Int: SessionHub] = [:]
    private var nextToken = 0

    func subscribe(sessionId: Int) -> AsyncStream<IrisChatWebsocketDTO> {
        nextToken += 1
        let token = nextToken

        let (stream, continuation) = AsyncStream<IrisChatWebsocketDTO>.makeStream()

        if hubs[sessionId] == nil {
            hubs[sessionId] = SessionHub(task: makeReaderTask(sessionId: sessionId))
        }
        hubs[sessionId]?.consumers[token] = continuation

        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeConsumer(sessionId: sessionId, token: token) }
        }

        return stream
    }

    func unsubscribeAll() {
        hubs.values.forEach { $0.task.cancel() }
        hubs.removeAll()
    }

    /// The single STOMP reader for a session: decodes frames and fans them out to
    /// every current consumer. Runs until the hub is torn down (task cancelled).
    private func makeReaderTask(sessionId: Int) -> Task<Void, Never> {
        let topic = IrisWebsocketTopic.makeIrisChat(sessionId: sessionId)
        return Task.detached { [weak self] in
            let raw = ArtemisStompClient.shared.subscribe(to: topic)
            for await message in raw {
                if Task.isCancelled { break }
                guard let dto = JSONDecoder.getTypeFromSocketMessage(
                    type: IrisChatWebsocketDTO.self,
                    message: message
                ) else {
                    continue
                }
                await self?.broadcast(sessionId: sessionId, dto: dto)
            }
        }
    }

    private func broadcast(sessionId: Int, dto: IrisChatWebsocketDTO) {
        hubs[sessionId]?.consumers.values.forEach { $0.yield(dto) }
    }

    private func removeConsumer(sessionId: Int, token: Int) {
        hubs[sessionId]?.consumers.removeValue(forKey: token)
        let remaining = hubs[sessionId]?.consumers.count ?? 0
        guard remaining == 0 else { return }
        // Debounce: a quick resubscribe (e.g. the surviving instance of a churny
        // transition) keeps the hub alive instead of bouncing the socket.
        Task { [weak self] in
            try? await Task.sleep(for: Self.unsubscribeDebounce)
            await self?.teardownIfEmpty(sessionId: sessionId)
        }
    }

    private func teardownIfEmpty(sessionId: Int) {
        guard let hub = hubs[sessionId], hub.consumers.isEmpty else { return }
        hub.task.cancel()
        hubs.removeValue(forKey: sessionId)
    }
}
