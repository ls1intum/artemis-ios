//
//  File.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

import Foundation
import UserStore

public protocol BaseMessage: Codable {
    var id: Int64 { get }
    var author: ConversationUser? { get }
    var creationDate: Date? { get }
    var content: String? { get }
    var tokenizedContent: String? { get }
    var authorRoleTransient: UserRole? { get }
    var reactions: [Reaction]? { get }
}

public extension BaseMessage {
    func containsReactionFromMe(emojiId: String) -> Bool {
        getReactionFromMe(emojiId: emojiId) != nil
    }

    func getReactionFromMe(emojiId: String) -> Reaction? {
        guard let userId = UserSession.shared.userId else { return nil }
        return (reactions ?? []).first(where: {
            guard let authorId = $0.user?.id else { return false }
            return authorId == userId && $0.emojiId == emojiId
        })
    }
}
