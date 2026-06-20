//
//  IrisChatWebsocketDTO.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 09.05.26.
//

import SharedModels

/// Wire format for messages pushed over the Iris STOMP topic
/// `/user/topic/iris/{sessionId}`. Mirrors the server `IrisChatWebsocketDTO`.
/// - `MESSAGE` payloads carry a new/updated message together with the current
///   stage snapshot.
/// - `STATUS` payloads carry only stage updates (and optionally suggestions).
struct IrisChatWebsocketDTO: Decodable, Hashable {
    let type: IrisChatWebsocketPayloadType
    let message: IrisMessageResponseDTO?
    let stages: [IrisStageDTO]?
    let rateLimitInfo: IrisRateLimitInformation?
    let suggestions: [String]?
    /// Live updates of the server-generated session title.
    let sessionTitle: String?
    let citationInfo: [IrisCitationMetaDTO]?
}

enum IrisChatWebsocketPayloadType: String, ConstantsEnum {
    case message = "MESSAGE"
    case status = "STATUS"
    case unknown
}
