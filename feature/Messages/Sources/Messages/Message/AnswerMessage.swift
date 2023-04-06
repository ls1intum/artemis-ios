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
    var author: User
    var creationDate: Date
    var content: String
    var tokenizedContent: String
    var authorRoleTransient: UserRole?

    var resolvesPost = false
    var reactions = Set<Reaction>()
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
