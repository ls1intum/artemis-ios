//
//  NavigationDestinationThreadViewModifier.swift
//
//
//  Created by Nityananda Zbil on 07.02.24.
//

import SwiftUI

/// Navigates to a thread view of a message.
public struct NavigationDestinationThreadViewModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content.navigationDestination(for: MessagePath.self) { messagePath in
            MessageDetailView(viewModel: messagePath.conversationViewModel, message: messagePath.message)
        }
    }
}
