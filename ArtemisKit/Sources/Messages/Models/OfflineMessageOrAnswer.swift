//
//  OfflineMessageOrAnswer.swift
//
//
//  Created by Nityananda Zbil on 08.03.24.
//

import Foundation
import SharedModels

struct OfflineMessageOrAnswer: BaseMessage {
    var id: Int64 = 0
    var author: ConversationUser?
    var creationDate: Date?
    var updatedDate: Date?
    var content: String?
    var tokenizedContent: String?
    var authorRole: UserRole?
    var reactions: [Reaction]?
}

extension OfflineMessageOrAnswer {
    init(_ message: ConversationOfflineMessageModel) {
        self.creationDate = message.date
        self.content = message.text
    }

    init(_ answer: MessageOfflineAnswerModel) {
        self.creationDate = answer.date
        self.content = answer.text
    }
}
