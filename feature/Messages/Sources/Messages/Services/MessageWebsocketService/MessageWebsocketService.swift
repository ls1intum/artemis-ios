//
//  MessageWebsocketService.swift
//  
//
//  Created by Sven Andabaka on 11.05.23.
//

import Foundation
import SharedModels

protocol MessageWebsocketService {
    func subscribeToConversationMembershipTopicStream(for courseId: Int) -> AsyncStream<Message>
}

enum MessageWebsocketServiceFactory {
    static let shared: MessageWebsocketService = MessageWebsocketServiceImpl.shared
}
