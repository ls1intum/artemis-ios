//
//  ConversationWebsocketDTO.swift
//  
//
//  Created by Sven Andabaka on 11.05.23.
//

import SharedModels

enum MetisCrudAction: String, RawRepresentable, Codable {
    case create = "CREATE"
    case update = "UPDATE"
    case delete = "DELETE"
    case newMessage = "NEW_MESSAGE"
}

struct ConversationWebsocketDTO: Codable {
    let conversation: Conversation
    let action: MetisCrudAction
}
