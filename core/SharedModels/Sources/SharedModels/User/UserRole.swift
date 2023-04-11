//
//  UserRole.swift
//  
//
//  Created by Sven Andabaka on 06.04.23.
//

import Foundation

public enum UserRole: String, RawRepresentable, Codable {
    case instructor = "INSTRUCTOR"
    case tutor = "TUTOR"
    case user = "USER"
}
