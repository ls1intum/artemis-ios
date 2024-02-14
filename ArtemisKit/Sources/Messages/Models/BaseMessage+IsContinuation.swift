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
    /// `isContinuation` computes if the same author messaged multiple times within 5 minutes.
    func isContinuation(of message: some BaseMessage) -> Bool {
        guard author == message.author,
              let lhs = creationDate,
              let rhs = message.creationDate else {
            return false
        }

        return lhs < rhs.addingTimeInterval(TimeInterval(MAX_MINUTES_FOR_GROUPING_MESSAGES * 60))
    }
}
