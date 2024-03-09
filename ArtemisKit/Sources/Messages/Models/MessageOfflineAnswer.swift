//
//  MessageOfflineAnswer.swift
//
//
//  Created by Nityananda Zbil on 09.03.24.
//

import Foundation
import SharedModels

struct MessageOfflineAnswer: BaseMessage {
    var id: Int64
    var author: SharedModels.ConversationUser?
    var creationDate: Date?
    var updatedDate: Date?
    var content: String?
    var tokenizedContent: String?
    var authorRoleTransient: SharedModels.UserRole?
    var reactions: [SharedModels.Reaction]?
}

extension MessageOfflineAnswer {
    init(_ message: MessageOfflineAnswerModel) {
        self.init(
            id: 0,
            author: ConversationUser?.none,
            creationDate: message.date,
            updatedDate: Date?.none,
            content: message.text,
            tokenizedContent: String?.none,
            authorRoleTransient: UserRole?.none,
            reactions: [Reaction]?.none)
    }
}
