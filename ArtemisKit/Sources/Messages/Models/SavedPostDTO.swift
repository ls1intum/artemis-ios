//
//  SavedPostDTO.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 15.03.25.
//

import DesignLibrary
import SharedModels
import SwiftUI

struct SavedPostDTO: Codable, Identifiable, Hashable, Comparable {
    static func < (lhs: SavedPostDTO, rhs: SavedPostDTO) -> Bool {
        lhs.id < rhs.id
    }

    let id: Int
    let author: AuthorDTO
    let role: UserRole?
    let creationDate: Date
    let content: String
    let isSaved: Bool
    let savedPostStatus: SavedPostStatus
    let reactions: [ReactionDTO]?
    let conversation: ConversationDTO
    let postingType: PostType
    let referencePostId: Int64
}

enum PostType: Int, Codable {
    case post, answer
}

enum SavedPostStatus: Int, Codable, FilterPicker {
    case inProgress, completed, archived

    var displayName: String {
        switch self {
        case .inProgress:
            R.string.localizable.inProgress()
        case .completed:
            R.string.localizable.done()
        case .archived:
            R.string.localizable.archived()
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
    let id: Int64
    let name: String
    let imageUrl: String?
}

struct ReactionDTO: Codable, Identifiable, Hashable {
    let id: Int
    let user: AuthorDTO
    let creationDate: Date
    let emojiId: String
}

struct ConversationDTO: Codable, Identifiable, Hashable {
    let id: Int64
    let title: String?
    // ConversationType type
}
