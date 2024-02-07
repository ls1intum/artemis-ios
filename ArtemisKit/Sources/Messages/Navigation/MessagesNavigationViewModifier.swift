//
//  MessagesNavigationViewModifier.swift
//
//
//  Created by Nityananda Zbil on 07.02.24.
//

import SwiftUI

public struct MessagesNavigationViewModifier: ViewModifier {
    public init () {}

    public func body(content: Content) -> some View {
        content
            .navigationDestination(for: MessagePath.self) { messagePath in
                if let message = messagePath.message {
                    MessageDetailView(viewModel: messagePath.conversationViewModel, message: message)
                } else {
                    MessageDetailView(
                        viewModel: ConversationViewModel(
                            courseId: messagePath.coursePath.id,
                            conversationId: messagePath.conversationPath.id),
                        messageId: messagePath.id)
                }
            }
    }
}
