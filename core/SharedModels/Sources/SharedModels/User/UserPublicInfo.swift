//
//  UserPublicInfo.swift
//  
//
//  Created by Sven Andabaka on 05.04.23.
//

import Foundation

public protocol UserPublicInfo: Codable {
    var id: Int64 { get }
    var login: String? { get }
    var name: String? { get }
    var firstName: String? { get }
    var lastName: String? { get }
    var isInstructor: Bool? { get }
    var isEditor: Bool? { get }
    var isTeachingAssistant: Bool? { get }
    var isStudent: Bool? { get }
}
