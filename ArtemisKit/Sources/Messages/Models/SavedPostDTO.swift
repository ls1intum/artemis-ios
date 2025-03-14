//
//  File.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 15.03.25.
//

import SharedModels

struct SavedPostDTO: Codable {
    let id: Int
    let author: AuthorDTO
    let role: UserRole
    // ZonedDateTime creationDate, ZonedDateTime updatedDate,
    let content: String
    let isSaved: Bool
    // short savedPostStatus,
    let reactions: [ReactionDTO]
    let conversation: ConversationDTO
    // short postingType
    let referencePostId: Int
}

struct AuthorDTO: Codable {
    let id: Int
    let name: String
    let imageUrl: String
}

struct ReactionDTO: Codable {
    let id: Int
    let user: AuthorDTO
    // ZonedDateTime creationDate
    let emojiId: String
}

struct ConversationDTO: Codable {
    let id: Int
    let title: String
    // ConversationType type
}
