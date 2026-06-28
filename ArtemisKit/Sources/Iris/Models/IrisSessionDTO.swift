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

    /// Returns a copy with the title replaced by `title` — used to reflect a
    /// freshly generated/updated session title in the list row.
    func withTitle(_ title: String?) -> IrisSessionDTO {
        IrisSessionDTO(
            id: id,
            title: title,
            creationDate: creationDate,
            mode: mode,
            entityId: entityId,
            entityName: entityName)
    }
}
