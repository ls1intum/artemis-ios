//
//  SessionContext.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 05.06.26.
//

import Foundation
import Navigation
import SharedModels

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

extension SessionContext {
    /// The context for a lecture's Iris chat.
    init(lecture: Lecture) {
        self.init(mode: .lecture, entityId: lecture.id, entityName: lecture.title)
    }

    /// Rebuilds the context from a navigation ``IrisContextSource`` handed off by
    /// an "Ask Iris" button. Not failable: the source already carries the resolved mode.
    init(source: IrisContextSource) {
        self.init(mode: IrisChatMode(rawValue: source.modeRawValue) ?? .unknown,
                  entityId: source.entityId, entityName: source.entityName)
    }

    /// This context as a navigation payload for an "Ask Iris" button handoff.
    var contextSource: IrisContextSource {
        IrisContextSource(modeRawValue: mode.rawValue, entityId: entityId, entityName: entityName)
    }
}
