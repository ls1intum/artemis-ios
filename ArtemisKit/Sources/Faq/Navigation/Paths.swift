//
//  Paths.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.10.24.
//

import SharedModels
import SwiftUI

public struct FaqPath: Hashable {
    public static func == (lhs: FaqPath, rhs: FaqPath) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public let id: Int64
    public let courseId: Int?
    public let faq: FaqDTO?
    public let namespace: Namespace.ID?

    public init(faq: FaqDTO, namespace: Namespace.ID?) {
        self.faq = faq
        self.id = faq.id
        self.namespace = namespace
        self.courseId = nil
    }

    public init(id: Int64, courseId: Int, namespace: Namespace.ID? = nil) {
        self.id = id
        self.courseId = courseId
        self.faq = nil
        self.namespace = namespace
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
