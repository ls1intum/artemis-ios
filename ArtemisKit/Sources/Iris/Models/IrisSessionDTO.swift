//
//  IrisSessionDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import Foundation

/// Slim session shape returned by `/chat/{courseId}/sessions/overview`,
/// used to render the chat-history list. Does **not** contain messages.
public struct IrisSessionDTO: Codable, Hashable, Identifiable {
    public let id: Int
    public let title: String?
    public let creationDate: Date
    public let mode: ChatServiceMode
    public let entityId: Int
    public let entityName: String?
}
