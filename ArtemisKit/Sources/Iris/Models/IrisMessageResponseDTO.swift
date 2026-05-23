//
//  IrisMessageResponseDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import Foundation

/// Wire format for a single content block as it comes off the network.
struct IrisMessageContentResponseDTO: Codable, Hashable {
    let id: Int?
    let type: String
    let textContent: String?
    let attributes: String?
}

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
