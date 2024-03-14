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
    let message: Binding<DataState<Message>>
    let conversationPath: ConversationPath
    let conversationViewModel: ConversationViewModel

    init?(
        message: Binding<DataState<Message>>,
        conversationPath: ConversationPath,
        conversationViewModel: ConversationViewModel
    ) {
        guard let id = message.wrappedValue.value?.id else {
            return nil
        }

        self.id = id
        self.message = message
        self.conversationPath = conversationPath
        self.conversationViewModel = conversationViewModel
    }

    static func == (lhs: MessagePath, rhs: MessagePath) -> Bool {
        lhs.id == rhs.id && lhs.conversationPath == rhs.conversationPath
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
