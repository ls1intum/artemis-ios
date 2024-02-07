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
    let message: Binding<DataState<BaseMessage>>?
    let coursePath: CoursePath
    let conversationPath: ConversationPath
    let conversationViewModel: ConversationViewModel

    init?(
        message: Binding<DataState<BaseMessage>>,
        coursePath: CoursePath,
        conversationPath: ConversationPath,
        conversationViewModel: ConversationViewModel
    ) {
        guard let id = message.wrappedValue.value?.id else {
            return nil
        }

        self.id = id
        self.message = message
        self.coursePath = coursePath
        self.conversationPath = conversationPath
        self.conversationViewModel = conversationViewModel // Thread
    }

    static func == (lhs: MessagePath, rhs: MessagePath) -> Bool {
        lhs.id == rhs.id && lhs.coursePath == rhs.coursePath && lhs.conversationPath == rhs.conversationPath
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
