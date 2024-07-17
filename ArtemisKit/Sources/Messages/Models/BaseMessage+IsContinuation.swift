//
//  BaseMessage+IsContinuation.swift
//
//
//  Created by Nityananda Zbil on 07.02.24.
//

import Foundation
import SharedModels

// swiftlint:disable:next identifier_name
private let MAX_MINUTES_FOR_GROUPING_MESSAGES = 5

extension BaseMessage {
    /// Whether the same author messaged multiple times within 5 minutes.
    func isContinuation(of message: BaseMessage?) -> Bool {
        guard let message,
              author == message.author,
              let lhs = creationDate,
              let rhs = message.creationDate else {
            return false
        }

        return lhs < rhs.addingTimeInterval(TimeInterval(MAX_MINUTES_FOR_GROUPING_MESSAGES * 60))
    }
}

// https://stackoverflow.com/a/30593673
extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
