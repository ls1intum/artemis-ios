//
//  WithImage.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 06.06.26.
//

import Foundation
import UserStore

/// Conform to this protocol to convert `imageUrl`s without /api/core/files to usable URLs
public protocol WithImage {
    var imageUrl: String? { get }
    var imageURL: String? { get }
    var imagePath: URL? { get }
}

public extension WithImage {
    var imageUrl: String? { nil }
    var imageURL: String? { nil }

    var imagePath: URL? {
        return self.image(for: \.imageUrl) ?? self.image(for: \.imageURL)
    }

    func image(for path: KeyPath<Self, String?>) -> URL? {
        guard let pathString = self[keyPath: path] else { return nil }
        return UserSessionFactory.shared.institution?.baseURL?
            .appending(path: "api/core/files")
            .appending(path: pathString)
    }
}
