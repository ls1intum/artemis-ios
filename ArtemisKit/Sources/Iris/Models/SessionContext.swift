//
//  SessionContext.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 05.06.26.
//

import Foundation

/// A local model identifying the Iris context a session belongs to.
/// Mirrors the TS `SessionContext` interface.
struct SessionContext: Hashable, Codable {
    let mode: IrisChatMode
    let entityId: Int
    let entityName: String?

    init(mode: IrisChatMode, entityId: Int, entityName: String? = nil) {
        self.mode = mode
        self.entityId = entityId
        self.entityName = entityName
    }
}
