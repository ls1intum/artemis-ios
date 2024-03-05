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
    @ViewBuilder let content: (Course, Conversation) -> Content

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
    }
}

public extension ConversationPathView where Content == ConversationView {
    init(path: ConversationPath) {
        self.init(viewModel: ConversationPathViewModel(path: path), content: Content.init)
    }
}
