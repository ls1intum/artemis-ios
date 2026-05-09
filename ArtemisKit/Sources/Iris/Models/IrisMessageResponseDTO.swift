//
//  IrisMessageResponseDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import Foundation

/// Wire format for a single content block as it comes off the network.
/// `attributes` is a JSON-encoded string when `type == "json"` and is parsed
/// into `IrisJsonAttributes` only at the domain boundary.
struct IrisMessageContentResponseDTO: Codable, Hashable {
    let id: Int64?
    let type: String
    let textContent: String?
    let attributes: String?
}

/// Wire format for a message returned by REST endpoints and WebSocket payloads.
/// Mirrors the server `IrisMessageResponseDTO` record. Use this type at the
/// HTTP/WebSocket boundary; map to `IrisMessage` domain types for app use.
struct IrisMessageResponseDTO: Codable, Hashable, Identifiable {
    let id: Int64?
    let sentAt: Date?
    let helpful: Bool?
    let sender: IrisSender
    let content: [IrisMessageContentResponseDTO]
    let accessedMemories: [MemirisMemory]?
    let createdMemories: [MemirisMemory]?
    let messageDifferentiator: Int?
}
