//
//  MessageWebsocketDTO.swift
//  
//
//  Created by Sven Andabaka on 11.05.23.
//

import Foundation
import SharedModels

struct MessageWebsocketDTO: Codable {
    let post: Message
    let action: MetisPostAction
}
