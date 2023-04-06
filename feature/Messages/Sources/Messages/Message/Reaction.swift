//
//  File.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

import Foundation
import SharedModels

struct Reaction: Codable {
    var id: Int64
    var user: ConversationUser?
    var creationDate: Date?
    var emojiId: String
    var post: Message?
    var answerPost: AnswerMessage?
}

extension Reaction: Equatable, Hashable {
    static func == (lhs: Reaction, rhs: Reaction) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
