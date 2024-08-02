//
//  MessagePath.swift
//
//
//  Created by Nityananda Zbil on 07.02.24.
//

import Common
import Navigation
import SharedModels
import SwiftUI

struct MessagePath: Hashable {
    let id: Int64
    let message: Binding<DataState<BaseMessage>>
    let conversationPath: ConversationPath
    let conversationViewModel: ConversationViewModel
    let presentKeyboardOnAppear: Bool

    init?(
        message: Binding<DataState<BaseMessage>>,
        conversationPath: ConversationPath,
        conversationViewModel: ConversationViewModel,
        presentKeyboardOnAppear: Bool = false
    ) {
        guard let id = message.wrappedValue.value?.id else {
            return nil
        }

        self.id = id
        self.message = message
        self.conversationPath = conversationPath
        self.conversationViewModel = conversationViewModel
        self.presentKeyboardOnAppear = presentKeyboardOnAppear
    }

    static func == (lhs: MessagePath, rhs: MessagePath) -> Bool {
        lhs.id == rhs.id && lhs.conversationPath == rhs.conversationPath
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
