//
//  IrisWebsocketService.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 19.05.26.
//

import Common

/// Streams Iris WebSocket payloads for a given chat session.
///
/// One ``AsyncStream`` per ``subscribe(sessionId:)`` call, backed by a single
/// STOMP subscription on `/user/topic/iris/{sessionId}`. Single-consumer:
/// re-subscribing to the same session replaces the previous stream.
/// Cleanup is explicit via ``unsubscribe(sessionId:)`` (or
/// ``unsubscribeAll()`` on logout / user change).
protocol IrisWebsocketService: Sendable {
    func subscribe(sessionId: Int64) async -> AsyncStream<IrisChatWebsocketDTO>
    func unsubscribe(sessionId: Int64) async
    func unsubscribeAll() async
}

enum IrisWebsocketServiceFactory: DependencyFactory {
    static let liveValue: IrisWebsocketService = IrisWebsocketServiceImpl()
}
