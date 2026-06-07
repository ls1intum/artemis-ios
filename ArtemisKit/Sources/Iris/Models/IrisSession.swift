//
//  IrisSession.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import Foundation

/// Wire format returned by `/chat/sessions/current`, `/chat/sessions` and
/// `/chat/{courseId}/session/{sessionId}`. Mirrors the server `IrisSession`.
/// `messages` carries the raw response DTOs; the chat service maps them to the
/// `IrisMessage` domain type when populating UI state.
struct IrisSession: Decodable, Hashable, Identifiable {
    let id: Int
    let userId: Int
    let messages: [IrisMessageResponseDTO]?
    /// Server-encoded JSON string of the most recent suggestion array, when present.
    let latestSuggestions: String?
    let title: String?
    let creationDate: Date
    let mode: IrisChatMode?
    let entityId: Int
    let citationInfo: [IrisCitationMetaDTO]?
}
