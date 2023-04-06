//
//  File.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

import Foundation
import SharedModels

protocol BaseMessage: Codable {
    var id: Int64 { get }
    var author: ConversationUser? { get }
    var creationDate: Date? { get }
    var content: String? { get }
    var tokenizedContent: String? { get }
    var authorRoleTransient: UserRole? { get }
}
