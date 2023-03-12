//
//  File.swift
//
//
//  Created by Sven Andabaka on 26.01.23.
//

import Foundation

public struct UserFacingError: Codable {
    public var title: String
    public var status: Int?
    public var detail: String?
    public var message: String?
    public var path: String?
    public var code: String?
    public var type: URL?

    public var description: String {
        return detail ?? message ?? title
    }

    public init(title: String) {
        self.title = title
    }
}

extension UserFacingError: LocalizedError {
    public var errorDescription: String? {
        var description = title
        if let message {
            description += "\nMessage: \(message)"
        }
        if let detail {
            description += "\nDetail: \(detail)"
        }
        return description
    }
}

extension UserFacingError: Equatable { }
