//
//  File.swift
//  
//
//  Created by Sven Andabaka on 05.04.23.
//

import Foundation

public struct ConversationUser: UserPublicInfo {
    public var id: Int64
    public var login: String?
    public var name: String?
    public var firstName: String?
    public var lastName: String?
    public var isInstructor: Bool?
    public var isEditor: Bool?
    public var isTeachingAssistant: Bool?
    public var isStudent: Bool?

    public var isChannelModerator: Bool?
    public var isRequestingUser: Bool?
}

extension ConversationUser: Hashable { }
