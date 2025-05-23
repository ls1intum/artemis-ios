//
//  ForwardedMessageDTO.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 16.05.25.
//

struct ForwardedMessageDTO: Codable {
    let sourceId: Int64
    let sourceType: PostType

    // Members needed for creating forwarded posts
    let destinationPostId: Int64?
    let content: String?
    // Other members like id and destinationAnswerPostId are pointless and thus not decoded
}
