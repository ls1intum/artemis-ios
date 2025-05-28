//
//  ForwardMessageView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.05.25.
//

import DesignLibrary
import SharedModels
import SwiftUI

struct ForwardMessageView: View {
    let viewModel: MessageActionsViewModel

    @State private var sendViewModel: SendMessageViewModel

    init(viewModel: MessageActionsViewModel) {
        self.viewModel = viewModel

        let course = viewModel.conversationViewModel.course
        let conversation = viewModel.conversationViewModel.conversation
        let delegate = SendMessageViewModelDelegate(presentError: viewModel.conversationViewModel.presentError,
                                                    sendMessage: viewModel.forwardMessage)

        _sendViewModel = State(initialValue: SendMessageViewModel(course: course,
                                                                  conversation: conversation,
                                                                  configuration: .forwardMessage,
                                                                  delegate: delegate,
                                                                  presentKeyboardOnAppear: true))
    }

    var conversationName: String {
        viewModel.selectedConversation?.baseConversation.conversationName ?? "Select…"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                NavigationLink {
                    PickConversationView(viewModel: viewModel)
                } label: {
                    HStack {
                        Text(R.string.localizable.conversation())
                        Spacer()
                        Text("\(conversationName) \(Image(systemName: "chevron.forward"))")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.m * 1.5)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .cardModifier(backgroundColor: .gray.opacity(0.2))
                .padding()

                Spacer()

                ForwardMessagePreviewView(viewModel: viewModel)

                SendMessageView(viewModel: sendViewModel)
            }
            .navigationTitle(R.string.localizable.forwardMessage())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(R.string.localizable.cancel()) {
                        viewModel.showForwardSheet = false
                    }
                }
            }
        }
        .fontWeight(.regular)
        .onAppear {
            viewModel.selectedConversation = viewModel.conversationViewModel.conversation
        }
    }
}

private struct ForwardMessagePreviewView: View {
    let viewModel: MessageActionsViewModel
    @StateObject var conversationViewModel: ConversationViewModel

    init(viewModel: MessageActionsViewModel) {
        self.viewModel = viewModel

        let cViewModel = ConversationViewModel(course: viewModel.conversationViewModel.course, conversation: viewModel.conversationViewModel.conversation, skipLoadingData: true)
        // Add viewModel's message as source for Message with id 0
        cViewModel.forwardedSourcePosts = [
            .init(id: 0, messages: [
                .init(sourceId: 0, sourceType: .post, destinationPostId: nil)
            ], sourceMessage: viewModel.message.value)
        ]
        self._conversationViewModel = StateObject(wrappedValue: cViewModel)
    }

    var body: some View {
        ForwardedMessageView(viewModel: conversationViewModel, message: previewContainer)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
    }

    var previewContainer: Message {
        // Message with id 0 for preview
        var message = Message(id: 0)
        message.hasForwardedMessages = true
        return message
    }
}

private struct PickConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MessageActionsViewModel
    @State private var searchText = ""

    var body: some View {
        DataStateView(data: $viewModel.allConversations) {
            await viewModel.loadConversations()
        } content: { conversations in
            List {
                let conversations = searchText.isEmpty ? conversations : conversations.filter {
                    $0.baseConversation.conversationName.localizedStandardContains(searchText)
                }
                ForEach(conversations) { conversation in
                    Button {
                        viewModel.selectedConversation = conversation
                        dismiss()
                    } label: {
                        ConversationRowLabel(conversation: conversation.baseConversation)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
        .navigationTitle(R.string.localizable.conversation())
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if case .loading = viewModel.allConversations {
                await viewModel.loadConversations()
            }
        }
    }
}
