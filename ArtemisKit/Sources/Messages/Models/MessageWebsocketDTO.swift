//
//  MessageWebsocketDTO.swift
//  
//
//  Created by Sven Andabaka on 11.05.23.
//

import SharedModels

struct MessageWebsocketDTO: Codable {
    let post: Message
    let action: MetisCrudAction
    let notification: Notification?
}

// Used in the web client's notification service.
struct Notification: Codable {}
