//
//  File.swift
//  
//
//  Created by Sven Andabaka on 05.04.23.
//

import Foundation
import SwiftUI

public struct UnknownConversation: BaseConversation {
    public var type: ConversationType
    public var id: Int64
    public var creationDate: Date?
    public var lastMessageDate: Date?
    public var creator: ConversationUser?
    public var lastReadDate: Date?
    public var unreadMessagesCount: Int?
    public var isFavorite: Bool?
    public var isHidden: Bool?
    public var isCreator: Bool?
    public var isMember: Bool?
    public var numberOfMembers: Int?

    public var conversationName: String {
        return "?"
    }

    public var icon: Image? {
        nil
    }
}
