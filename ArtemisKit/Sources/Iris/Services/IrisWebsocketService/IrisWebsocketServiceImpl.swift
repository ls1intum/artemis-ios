//
//  IrisWebsocketServiceImpl.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 19.05.26.
//

import APIClient
import Common
import Foundation

/// Decodes Iris WebSocket payloads for a chat session into a typed stream.
///
/// Single-consumer: each ``subscribe(sessionId:)`` call replaces any
/// existing subscription for that session. The decode pump runs on a
/// detached task; cancelling it (via ``unsubscribe(sessionId:)`` or
/// ``unsubscribeAll()``) drops the STOMP subscription downstream.
actor IrisWebsocketServiceImpl: IrisWebsocketService {

    private var sessions: [Int: Task<Void, Never>] = [:]

    func subscribe(sessionId: Int) -> AsyncStream<IrisChatWebsocketDTO> {
        sessions.removeValue(forKey: sessionId)?.cancel()

        let (stream, continuation) = AsyncStream<IrisChatWebsocketDTO>.makeStream()
        let topic = IrisWebsocketTopic.makeIrisChat(sessionId: sessionId)

        let task = Task.detached {
            let raw = ArtemisStompClient.shared.subscribe(to: topic)
            for await message in raw {
                if Task.isCancelled { break }
                guard let dto = JSONDecoder.getTypeFromSocketMessage(
                    type: IrisChatWebsocketDTO.self,
                    message: message
                ) else {
                    continue
                }
                continuation.yield(dto)
            }
            continuation.finish()
        }
        sessions[sessionId] = task

        continuation.onTermination = { _ in task.cancel() }

        return stream
    }

    func unsubscribe(sessionId: Int) {
        sessions.removeValue(forKey: sessionId)?.cancel()
    }

    func unsubscribeAll() {
        sessions.values.forEach { $0.cancel() }
        sessions.removeAll()
    }
}
