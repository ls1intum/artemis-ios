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
    var title: String?
    let creationDate: Date
    let mode: IrisChatMode
    let entityId: Int
    let entityName: String?

    /// The session's context as the local ``SessionContext`` model.
    var context: SessionContext {
        SessionContext(mode: mode, entityId: entityId, entityName: entityName)
    }

    /// Returns a copy with the context fields (mode/entityId/entityName) replaced by
    /// `context` — used to mirror a live context switch from the open chat back into
    /// the list row.
    func withContext(_ context: SessionContext) -> IrisSessionDTO {
        IrisSessionDTO(
            id: id,
            title: title,
            creationDate: creationDate,
            mode: context.mode,
            entityId: context.entityId,
            entityName: context.entityName)
    }
}
