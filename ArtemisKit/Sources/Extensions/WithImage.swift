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
        guard let image = imageUrl ?? imageURL else { return nil }
        return UserSessionFactory.shared.institution?.baseURL?
            .appending(path: "api/core/files")
            .appending(path: image)
    }
}
