//
//  File.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

import Foundation
import SharedModels

struct AnswerMessage: BaseMessage {

    var id: Int64
    var author: ConversationUser?
    var creationDate: Date?
    var content: String?
    var tokenizedContent: String?
    var authorRoleTransient: UserRole?

    var resolvesPost: Bool?
    var reactions: [Reaction]?
    var post: Message?
}

extension AnswerMessage: Equatable, Hashable {
    static func == (lhs: AnswerMessage, rhs: AnswerMessage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
