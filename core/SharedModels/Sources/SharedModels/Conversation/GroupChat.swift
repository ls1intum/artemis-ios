//
//  File.swift
//  
//
//  Created by Sven Andabaka on 05.04.23.
//

import Foundation
import SwiftUI

public struct GroupChat: BaseConversation {
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

    public var name: String?
    public var members: [ConversationUser]?

    public var conversationName: String {
        if let name, !name.isEmpty {
            return name
        }
        // fallback to the list of members if no name is set
        let containsCurrentUser = (members ?? []).first(where: { $0.isRequestingUser ?? false })
        let membersWithoutUser = (members ?? []).filter { $0.isRequestingUser == false }
        if membersWithoutUser.isEmpty {
            return containsCurrentUser == nil ? R.string.localizable.onlyYou() : ""
        }
        if membersWithoutUser.count < 3 {
            return membersWithoutUser
                .map { $0.name ?? "" }
                .joined(separator: ", ")
        }
        return "\(membersWithoutUser.map { $0.name ?? "" }.prefix(2).joined(separator: ", ")), \(R.string.localizable.others(membersWithoutUser.count - 2))"
    }

    public var icon: Image? {
        Image(systemName: "person.3.fill")
    }
}
