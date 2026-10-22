//
//  SendMessageViewModelDelegate.swift
//
//
//  Created by Nityananda Zbil on 28.02.24.
//

import Common
import SharedModels
import SwiftUI

@MainActor
struct SendMessageViewModelDelegate {
    var didEditMessage: ((BaseMessage) -> Void)?
    let presentError: (UserFacingError) -> Void
    /// Returns true once the message has been accepted by the persistent queue or server.
    let sendMessage: (String) async -> Bool

    init(presentError: @escaping (UserFacingError) -> Void, sendMessageWithResult: @escaping (String) async -> Bool) {
        self.presentError = presentError
        self.sendMessage = sendMessageWithResult
    }

    init(presentError: @escaping (UserFacingError) -> Void, sendMessage: @escaping (String) async -> Void) {
        self.init(presentError: presentError, sendMessageWithResult: { text in
            await sendMessage(text)
            return true
        })
    }
}
