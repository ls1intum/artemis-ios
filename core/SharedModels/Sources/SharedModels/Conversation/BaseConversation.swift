//
//  Conversation.swift
//  
//
//  Created by Sven Andabaka on 03.04.23.
//

import Foundation
import SwiftUI
import Common

public enum ConversationType: String, Codable {
    case oneToOneChat
    case groupChat
    case channel
    case unknown

    public init(from decoder: Decoder) {
        do {
            self = try ConversationType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
        } catch {
            self = .unknown
            log.error("Unknown Conversation Type!")
        }
    }
}

public protocol BaseConversation: Codable {
    var type: ConversationType { get }
    var id: Int64 { get }
    var creationDate: Date? { get }
    var lastMessageDate: Date? { get }
    var creator: ConversationUser? { get }
    var lastReadDate: Date? { get }
    var unreadMessagesCount: Int? { get }
    var isFavorite: Bool? { get }
    var isHidden: Bool? { get }
    var isCreator: Bool? { get }
    var isMember: Bool? { get }
    var numberOfMembers: Int? { get }

    // computed properties
    var conversationName: String { get }
    var icon: Image? { get }
}

public enum Conversation: Codable, Identifiable {

    fileprivate enum Keys: String, CodingKey {
        case type
    }

    case channel(conversation: Channel)
    case groupChat(conversation: GroupChat)
    case oneToOneChat(conversation: OneToOneChat)
    case unknown(conversation: UnknownConversation)

    public var baseConversation: any BaseConversation {
        switch self {
        case .channel(let conversation): return conversation
        case .groupChat(let conversation): return conversation
        case .oneToOneChat(let conversation): return conversation
        case .unknown(let conversation): return conversation
        }
    }

    public var id: Int64 {
        baseConversation.id
    }

    public init?(conversation: BaseConversation) {
        if let conversation = conversation as? Channel {
            self = .channel(conversation: conversation)
            return
        }
        if let conversation = conversation as? GroupChat {
            self = .groupChat(conversation: conversation)
            return
        }
        if let conversation = conversation as? OneToOneChat {
            self = .oneToOneChat(conversation: conversation)
            return
        }
        if let conversation = conversation as? UnknownConversation {
            self = .unknown(conversation: conversation)
            return
        }
        return nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(ConversationType.self, forKey: Keys.type)
        switch type {
        case .channel: self = .channel(conversation: try Channel(from: decoder))
        case .groupChat: self = .groupChat(conversation: try GroupChat(from: decoder))
        case .oneToOneChat: self = .oneToOneChat(conversation: try OneToOneChat(from: decoder))
        case .unknown: self = .unknown(conversation: try UnknownConversation(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .channel(let conversation):
            try conversation.encode(to: encoder)
        case .groupChat(let conversation):
            try conversation.encode(to: encoder)
        case .oneToOneChat(let conversation):
            try conversation.encode(to: encoder)
        case .unknown(let conversation):
            try conversation.encode(to: encoder)
        }
    }
}

extension Conversation: Equatable, Hashable {
    public static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id &&
        lhs.baseConversation.unreadMessagesCount == rhs.baseConversation.unreadMessagesCount &&
        lhs.baseConversation.isFavorite == rhs.baseConversation.isFavorite &&
        lhs.baseConversation.isHidden == rhs.baseConversation.isHidden
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
