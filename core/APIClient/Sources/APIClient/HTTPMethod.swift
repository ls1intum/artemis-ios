//
//  File.swift
//
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation

public enum HTTPMethod: String, CustomStringConvertible {
    case connect
    case delete
    case get
    case post
    case head
    case put
    case options
    case update

    public var description: String {
        return rawValue.uppercased()
    }
}
