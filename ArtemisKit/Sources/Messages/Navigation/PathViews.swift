//
//  PathViews.swift
//
//
//  Created by Nityananda Zbil on 05.03.24.
//

import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

public struct ConversationPathView<Content: View>: View {
    @State var viewModel: ConversationPathViewModel
    let content: (Course, Conversation) -> Content
    @Environment(\.horizontalSizeClass) var sizeClass

    public var body: some View {
        DataStateView(data: $viewModel.conversation) {
            await viewModel.loadConversation()
        } content: { conversation in
            CoursePathView(path: viewModel.path.coursePath) { course in
                content(course, conversation)
            }
        }
        .task {
            await viewModel.loadConversation()
        }
        // Hide the course Tab Bar when inside a conversation on iPhone
        .toolbar(sizeClass == .compact ? .hidden : .automatic, for: .tabBar)
    }
}

public extension ConversationPathView where Content == ConversationView {
    init(path: ConversationPath) {
        self.init(viewModel: ConversationPathViewModel(path: path), content: Content.init)
    }
}
