//
//  IrisMessageResponseDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import Foundation
import SharedModels

/// Wire format for a message returned by REST endpoints and WebSocket payloads.
/// Mirrors the server `IrisMessageResponseDTO` record.
struct IrisMessageResponseDTO: Codable, Hashable, Identifiable {
    let id: Int?
    let sentAt: Date?
    let helpful: Bool?
    let sender: IrisSender
    let content: [IrisMessageContentResponseDTO]
    let accessedMemories: [MemirisMemory]?
    let createdMemories: [MemirisMemory]?
    let messageDifferentiator: Int?
}

/// Distinguishes the author of an Iris message.
enum IrisSender: String, ConstantsEnum {
    case llm = "LLM"
    case user = "USER"
    case artifact = "ARTIFACT"
    case ctxswap = "CTXSWAP"
    case unknown
}

/// Wire format for a single content block as it comes off the network.
struct IrisMessageContentResponseDTO: Codable, Hashable {
    let id: Int?
    let type: IrisMessageContentType
    let textContent: String?
    /// JSON object whose keys depend on the block's purpose (context switch,
    /// MCQ, …). The server sends this as an object, not a string.
    let attributes: IrisContentAttributes?
}

/// Decoded `attributes` object of a content block. All fields are optional and
/// unknown keys are ignored, so non-context-switch json blocks (e.g. MCQs)
/// decode harmlessly instead of failing the whole message.
struct IrisContentAttributes: Codable, Hashable {
    /// Present only on context-switch messages.
    let transition: ContextSwitchTransition?
    let entityMode: IrisChatMode?
    let entityId: Int?
    let name: String?
}
