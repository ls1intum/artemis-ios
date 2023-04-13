//
//  File.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

import Foundation

public struct AnswerMessage: BaseMessage {

    public var id: Int64
    public var author: ConversationUser?
    public var creationDate: Date?
    public var content: String?
    public var tokenizedContent: String?
    public var authorRoleTransient: UserRole?

    public var resolvesPost: Bool?
    public var reactions: [Reaction]?
    public var post: Message?
}

extension AnswerMessage: Equatable, Hashable {
    public static func == (lhs: AnswerMessage, rhs: AnswerMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.reactions?.count ?? 0 == rhs.reactions?.count ?? 0 &&
        lhs.content == rhs.content
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
