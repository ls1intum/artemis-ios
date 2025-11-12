//
//  ConversationSearchResultsView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 11.11.25.
//

import SwiftUI

struct ConversationSearchResultsView: View {
    @Bindable var viewModel: ConversationSearchViewModel

    var body: some View {
        if viewModel.noResults {
            ContentUnavailableView.search
        }
        Group {
            conversationsSection
            if viewModel.isLoading {
                ProgressView()
            } else {
                messagesSection
            }
        }
        .listRowInsets(EdgeInsets(top: .m, leading: .m * 1.5, bottom: .m, trailing: .s))
        .listRowBackground(Color(uiColor: .secondarySystemBackground))
        .animation(.default, value: viewModel.isLoading)
    }

    @ViewBuilder var conversationsSection: some View {
        let conversations = viewModel.conversations
        if !conversations.isEmpty {
            Section {
                ForEach(conversations) { conversation in
                    ConversationRow(viewModel: viewModel.conversationListViewModel.parentViewModel,
                                    conversation: conversation.baseConversation)
                    .padding(.leading, .l)
                }
            } header: {
                SearchSectionHeader(title: R.string.localizable.conversations(),
                                    limitEnabled: $viewModel.limitConversations)
            }
        }
    }

    @ViewBuilder var messagesSection: some View {
        let messages = viewModel.limitedMessages
        if !messages.isEmpty || viewModel.isLoading {
            Section {
                ForEach(messages, id: \.id) { message in
                    if let author = message.author,
                       let creationDate = message.creationDate,
                       let conversation = message.conversation {
                        MessagePreview(user: author,
                                       userRole: message.authorRole,
                                       content: message.content,
                                       threadId: message.id,
                                       creationDate: creationDate,
                                       conversation: conversation,
                                       conversationName: conversation.baseConversation.conversationName,
                                       course: viewModel.conversationListViewModel.parentViewModel.course)
                    }
                }
            } header: {
                SearchSectionHeader(title: R.string.localizable.messages(),
                                    limitEnabled: $viewModel.limitMessages)
            }
        }
    }
}

private struct SearchSectionHeader: View {
    let title: String
    @Binding var limitEnabled: Bool

    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Button(limitEnabled ? R.string.localizable.showAll() : R.string.localizable.collapse()) {
                withAnimation {
                    limitEnabled.toggle()
                }
            }
        }
    }
}
