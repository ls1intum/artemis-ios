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
                                                                  delegate: delegate))
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
                        Text("Conversation")
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

                // TODO: Preview

                Text("Add a message")
                SendMessageView(viewModel: sendViewModel)
            }
            .navigationTitle("Forward message")
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
        .presentationDetents([.medium, .large])
        .onAppear {
            viewModel.selectedConversation = viewModel.conversationViewModel.conversation
        }
    }
}

private struct PickConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MessageActionsViewModel

    var body: some View {
        DataStateView(data: $viewModel.allConversations) {
            await viewModel.loadConversations()
        } content: { conversations in
            List {
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
        }
        .task {
            switch viewModel.allConversations {
            case .loading: await viewModel.loadConversations()
            default: break
            }
        }
    }
}
