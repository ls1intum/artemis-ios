//
//  IrisMessage.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import Foundation
import SharedModels

/// Distinguishes the author of an Iris message.
enum IrisSender: String, ConstantsEnum {
    case llm = "LLM"
    case user = "USER"
    case artifact = "ARTIFACT"
    case unknown
}

/// Domain message produced by the LLM. Holds typed content, parsed `sentAt`
/// and the optional Memiris references attached by the server.
struct IrisAssistantMessage: Hashable, Identifiable {
    let id: Int64
    let content: [IrisMessageContent]
    let sentAt: Date
    let helpful: Bool?
    let accessedMemories: [MemirisMemory]?
    let createdMemories: [MemirisMemory]?

    var sender: IrisSender { .llm }
}

/// Domain message authored by the current user.
struct IrisUserMessage: Hashable, Identifiable {
    let id: Int64?
    let content: [IrisTextMessageContent]
    let sentAt: Date?
    let messageDifferentiator: Int?
    let accessedMemories: [MemirisMemory]?
    let createdMemories: [MemirisMemory]?

    var sender: IrisSender { .user }
}

/// Domain message representing a server-generated artifact, e.g. a tutor
/// suggestion result that is attached to a message thread.
struct IrisArtifactMessage: Hashable, Identifiable {
    let id: Int64?
    let content: [IrisTextMessageContent]
    let sentAt: Date?
    let accessedMemories: [MemirisMemory]?
    let createdMemories: [MemirisMemory]?

    var sender: IrisSender { .artifact }
}

/// Discriminated union over the three sender-specific message variants.
/// Mirrors the TS `IrisMessage` type alias in `iris-message.model.ts`.
enum IrisMessage: Hashable, Identifiable {
    case assistant(IrisAssistantMessage)
    case user(IrisUserMessage)
    case artifact(IrisArtifactMessage)

    var id: Int64? {
        switch self {
        case .assistant(let message): message.id
        case .user(let message): message.id
        case .artifact(let message): message.id
        }
    }

    var sentAt: Date? {
        switch self {
        case .assistant(let message): message.sentAt
        case .user(let message): message.sentAt
        case .artifact(let message): message.sentAt
        }
    }

    var sender: IrisSender {
        switch self {
        case .assistant: .llm
        case .user: .user
        case .artifact: .artifact
        }
    }
}
