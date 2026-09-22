//
//  IrisWebsocketService.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 19.05.26.
//

import Common

/// Streams Iris WebSocket payloads for a given chat session.
///
/// One ``AsyncStream`` per ``subscribe(sessionId:)`` call, all backed by a single
/// STOMP subscription on `/user/topic/iris/{sessionId}`. Multi-consumer:
/// overlapping subscriptions to the same session coexist (each gets its own
/// stream). A consumer is cleaned up automatically when its stream is cancelled,
/// so callers just drive it from a SwiftUI `.task`. ``unsubscribeAll()`` drops
/// every subscription, e.g. when the course is closed.
protocol IrisWebsocketService: Sendable {
    func subscribe(sessionId: Int) async -> AsyncStream<IrisChatWebsocketDTO>
    func unsubscribeAll() async
}

enum IrisWebsocketServiceFactory: DependencyFactory {
    static let liveValue: IrisWebsocketService = IrisWebsocketServiceImpl()
}
