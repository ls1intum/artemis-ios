//
//  IrisSessionDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import Foundation

/// Slim session shape returned by `/chat/{courseId}/sessions/overview`,
/// used to render the chat-history list. Does **not** contain messages.
struct IrisSessionDTO: Codable, Hashable, Identifiable {
    let id: Int
    let title: String?
    let creationDate: Date
    let mode: ChatServiceMode
    let entityId: Int
    let entityName: String?
}
