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

    /// The context for an exercise's Iris chat, or `nil` for unsupported types.
    init?(exercise: Exercise) {
        guard let mode = IrisChatMode(exercise: exercise) else { return nil }
        self.init(mode: mode, entityId: exercise.id, entityName: exercise.baseExercise.title)
    }

    /// Rebuilds the context from a navigation ``IrisContextSource`` handed off by
    /// an "Ask Iris" button. `nil` for an exercise type Iris has no chat mode for.
    init?(source: IrisContextSource) {
        switch source {
        case .lecture(let lecture):
            self.init(lecture: lecture)
        case .exercise(let exercise):
            guard let context = SessionContext(exercise: exercise) else { return nil }
            self = context
        }
    }
}
