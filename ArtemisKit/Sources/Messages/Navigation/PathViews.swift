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

extension ConversationPathView {
    init(path: ConversationPath, @ViewBuilder content: @escaping (Course, Conversation) -> Content) {
        self.init(viewModel: ConversationPathViewModel(path: path), content: content)
    }
}

public extension ConversationPathView where Content == ConversationView {
    init(path: ConversationPath) {
        self.init(path: path, content: Content.init)
    }
}

// MARK: - MessagePathView

struct MessagePathView<Content: View>: View {
    @State var viewModel: MessagePathViewModel
    let content: (Course, Conversation, Message) -> Content

    var body: some View {
        DataStateView(data: $viewModel.message) {
            await viewModel.loadMessage()
        } content: { message in
            ConversationPathView(path: viewModel.path.conversationPath) { course, conversation in
                content(course, conversation, message)
            }
        }
    }
}

extension MessagePathView {
    init(path: MessagePath, @ViewBuilder content: @escaping (Course, Conversation, Message) -> Content) {
        self.init(viewModel: MessagePathViewModel(path: path), content: content)
    }
}

extension MessagePathView where Content == MessageDetailView {
    init(path: MessagePath) {
        self.init(path: path) { course, conversation, message in
            MessageDetailView(
                conversationViewModel: path.conversationViewModel,
                course: course,
                conversation: conversation,
                message: message)
        }
    }
}
