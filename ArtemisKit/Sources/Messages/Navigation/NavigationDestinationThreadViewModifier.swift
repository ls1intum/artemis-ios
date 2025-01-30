//
//  NavigationDestinationThreadViewModifier.swift
//
//
//  Created by Nityananda Zbil on 07.02.24.
//

import SwiftUI
import Navigation

/// Navigates to a thread view of a message or a conversation.
public struct NavigationDestinationMessagesModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .navigationDestination(for: MessagePath.self) { messagePath in
                MessageDetailView(viewModel: messagePath.conversationViewModel, message: messagePath.message, presentKeyboardOnAppear: messagePath.presentKeyboardOnAppear)
            }
            .navigationDestination(for: ConversationPath.self, destination: ConversationPathView.init)
            .navigationDestination(for: ThreadPath.self, destination: ThreadPathView.init)
    }
}
