//
//  ConversationSearchResultsView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 11.11.25.
//

import SwiftUI

struct ConversationSearchResultsView: View {
    let viewModel: ConversationSearchViewModel

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
                HStack {
                    Text("Conversations").font(.headline)
                    Spacer()
                    Button(viewModel.limitConversations ? "Show all" : "Collapse") {
                        withAnimation {
                            viewModel.limitConversations.toggle()
                        }
                    }
                }
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
                                       course: viewModel.conversationListViewModel.parentViewModel.course)
                    }
                }
            } header: {
                HStack {
                    Text("Messages").font(.headline)
                    Spacer()
                    Button(viewModel.limitMessages ? "Show all" : "Collapse") {
                        withAnimation {
                            viewModel.limitMessages.toggle()
                        }
                    }
                }
            }
        }
    }
}
