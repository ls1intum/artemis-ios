//
//  SendMessageViewModelDelegate.swift
//
//
//  Created by Nityananda Zbil on 28.02.24.
//

import Common
import SwiftUI

@MainActor
struct SendMessageViewModelDelegate {
    let loadMessages: () async -> Void
    let presentError: (UserFacingError) -> Void
    let scrollToId: (String) -> Void
}

extension SendMessageViewModelDelegate {
    init(_ conversationViewModel: ConversationViewModel) {
        self.loadMessages = conversationViewModel.loadMessages
        self.presentError = conversationViewModel.presentError(userFacingError:)
        self.scrollToId = { conversationViewModel.shouldScrollToId = $0 }
    }
}
