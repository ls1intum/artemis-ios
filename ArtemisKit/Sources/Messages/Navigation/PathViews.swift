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

@MainActor
public struct ConversationPathView<Content: View>: View {
    @State var viewModel: ConversationPathViewModel
    let content: (Course, Conversation) -> Content

    public var body: some View {
        DataStateView(data: $viewModel.conversation) {
            await viewModel.reloadConversation()
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

struct ThreadPathView: View {
    @State private var viewModel: ThreadPathViewModel

    var body: some View {
        DataStateView(data: $viewModel.message) {
            await viewModel.loadMessage()
        } content: { _ in
            CoursePathView(path: viewModel.path.coursePath) { course in
                MessageDetailView(viewModel: .init(course: course, conversation: viewModel.path.conversation, skipLoadingData: true),
                                  message: $viewModel.message)
            }
        }
        .task {
            await viewModel.loadMessage()
        }
    }
}

extension ThreadPathView {
    init(path: ThreadPath) {
        self.init(viewModel: ThreadPathViewModel(path: path))
    }
}
