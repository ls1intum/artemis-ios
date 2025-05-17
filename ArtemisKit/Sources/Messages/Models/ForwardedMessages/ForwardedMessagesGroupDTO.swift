//
//  ForwardedMessagesGroupDTO.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 16.05.25.
//

import SharedModels

struct ForwardedMessagesGroupDTO: Codable {
    let id: Int64
    let messages: [ForwardedMessageDTO]

    enum CodingKeys: CodingKey {
        case id, messages
    }

    // Property used for storing message after loading it
    var sourceMessage: (any BaseMessage)?
    var sourceMessageId: Int64? {
        messages.first?.sourceId
    }
    var sourceMessageType: PostType {
        messages.first?.sourceType ?? .unknown
    }
}
