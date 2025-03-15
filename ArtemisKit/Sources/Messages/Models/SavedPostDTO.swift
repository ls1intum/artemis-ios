//
//  SavedPostDTO.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 15.03.25.
//

import DesignLibrary
import SharedModels
import SwiftUI

struct SavedPostDTO: Codable, Identifiable, Hashable {
    let id: Int
    let author: AuthorDTO
    let role: UserRole?
    // ZonedDateTime creationDate, ZonedDateTime updatedDate,
    let content: String
    let isSaved: Bool
    // short savedPostStatus,
    let reactions: [ReactionDTO]?
    let conversation: ConversationDTO
    // short postingType
    let referencePostId: Int
}

enum SavedPostStatus: Int, Codable, FilterPicker {
    case inProgress, completed, archived

    var displayName: String {
        // TODO: Localize
        switch self {
        case .inProgress:
            "In Progress"
        case .completed:
            "Done"
        case .archived:
            "Archived"
        }
    }

    var selectedColor: Color {
        switch self {
        case .inProgress:
            .blue
        case .completed:
            .green
        case .archived:
            .gray
        }
    }

    var iconName: String {
        switch self {
        case .inProgress:
            "bookmark"
        case .completed:
            "checkmark.rectangle.stack"
        case .archived:
            "archivebox"
        }
    }

    var id: Int {
        hashValue
    }
}

struct AuthorDTO: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let imageUrl: String?
}

struct ReactionDTO: Codable, Identifiable, Hashable {
    let id: Int
    let user: AuthorDTO
    // ZonedDateTime creationDate
    let emojiId: String
}

struct ConversationDTO: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    // ConversationType type
}
