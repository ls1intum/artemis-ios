//
//  ForwardedMessageDTO.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 16.05.25.
//

struct ForwardedMessageDTO: Codable {
    let sourceId: Int64
    let sourceType: PostType
    // Other members like id, destinationPostId and destinationAnswerPostId are pointless and thus not decoded
}
