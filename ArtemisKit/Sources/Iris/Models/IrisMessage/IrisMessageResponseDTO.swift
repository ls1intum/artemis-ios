//
//  IrisMessageResponseDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import Foundation
import SharedModels

/// Wire format for a message returned by REST endpoints and WebSocket payloads.
/// Mirrors the server `IrisMessageResponseDTO` record. Receive-only, hence
/// `Decodable`: the send path uses ``IrisMessageRequestDTO`` instead.
struct IrisMessageResponseDTO: Decodable, Hashable, Identifiable {
    let id: Int?
    let sentAt: Date?
    let helpful: Bool?
    let sender: IrisSender
    let content: [IrisMessageContentResponseDTO]
    let accessedMemories: [MemirisMemory]?
    let createdMemories: [MemirisMemory]?
    let messageDifferentiator: Int?
}

extension IrisMessageResponseDTO {
    /// Non-nil when this message is a context switch: the server sends a json
    /// content block carrying a `transition` attribute instead of chat text.
    /// Drives rendering an ``IrisContextSwitchDivider`` in place of a bubble.
    var contextSwitch: IrisContextSwitchAttributes? {
        for case .contextSwitch(let attributes)? in content.map(\.attributes) {
            return attributes
        }
        return nil
    }
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
struct IrisMessageContentResponseDTO: Decodable, Hashable {
    let id: Int?
    let type: IrisMessageContentType
    let textContent: String?
    /// JSON object whose keys depend on the block's purpose (context switch,
    /// MCQ, …). The server sends this as an object, not a string.
    let attributes: IrisContentAttributes?
}

/// Decoded `attributes` object of a content block. The server keeps this field
/// generic; which payload it carries is decided by a specific marker key — `type`
/// for MCQ, `transition` for context switches. If no known marker is present
/// (e.g. a future payload type), it decodes to ``unknown`` instead of failing the
/// message.
enum IrisContentAttributes: Hashable {
    case contextSwitch(IrisContextSwitchAttributes)
    case unknown

    /// Family-specific marker keys. None is treated as a fallback: their
    /// absence is what defines ``unknown``.
    private enum MarkerKey: String, CodingKey {
        case transition  // context-switch
    }
}

extension IrisContentAttributes: Decodable {
    init(from decoder: Decoder) throws {
        let markers = try decoder.container(keyedBy: MarkerKey.self)

        // Context-switch : discriminated by `transition`.
        if markers.contains(.transition) {
            self = .contextSwitch(try IrisContextSwitchAttributes(from: decoder))
            return
        }

        // Neither marker present → unknown/future family.
        self = .unknown
    }
}

/// Wire format of a context-switch `attributes` block, discriminated by its
/// `transition` key. Decoded into ``IrisContentAttributes/contextSwitch(_:)``.
struct IrisContextSwitchAttributes: Decodable, Hashable {
    let transition: ContextSwitchTransition
    let entityMode: IrisChatMode?
    let entityId: Int?
    let name: String?
}

/// How the session's context changed, mirroring the web client's
/// `ContextSwitchTransition`.
enum ContextSwitchTransition: String, ConstantsEnum {
    case added
    case removed
    case changed
    case unknown
}
