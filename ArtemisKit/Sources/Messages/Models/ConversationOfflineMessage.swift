//
//  ConversationOfflineMessage.swift
//
//
//  Created by Nityananda Zbil on 08.03.24.
//

import Foundation
import SharedModels

struct ConversationOfflineMessage: BaseMessage {
    var id: Int64
    var author: ConversationUser?
    var creationDate: Date?
    var updatedDate: Date?
    var content: String?
    var tokenizedContent: String?
    var authorRoleTransient: SharedModels.UserRole?
    var reactions: [SharedModels.Reaction]?
}

extension ConversationOfflineMessage: Codable {}

extension ConversationOfflineMessage {
    init(_ model: ConversationOfflineMessageModel) {
        self.init(
            id: 0,
            author: ConversationUser?.none,
            creationDate: model.date,
            updatedDate: Date?.none,
            content: model.text,
            tokenizedContent: String?.none,
            authorRoleTransient: UserRole?.none,
            reactions: [Reaction]?.none)
    }
}
