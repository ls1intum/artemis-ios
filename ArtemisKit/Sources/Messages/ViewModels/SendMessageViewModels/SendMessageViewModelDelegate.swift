//
//  SendMessageViewModelDelegate.swift
//
//
//  Created by TUM School on 28.02.24.
//

import Common
import SwiftUI

@MainActor
struct SendMessageViewModelDelegate {
    let shouldScrollToId: (String) -> Void
    let loadMessages: () async -> Void
    let presentError: (UserFacingError) -> Void
}

extension SendMessageViewModelDelegate {
    init(_ conversationViewModel: ConversationViewModel) {
        self.shouldScrollToId = { conversationViewModel.shouldScrollToId = $0 }
        self.loadMessages = conversationViewModel.loadMessages
        self.presentError = conversationViewModel.presentError(userFacingError:)
    }
}
