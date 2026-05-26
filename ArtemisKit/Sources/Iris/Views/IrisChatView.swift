//
//  IrisChatView.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 25.05.26.
//

import ArtemisMarkdown
import DesignLibrary
import SwiftUI

struct IrisChatView: View {
    @State private var viewModel: IrisChatViewModel
    @State private var showDeleteConfirmation = false

    private let onDeleted: () -> Void

    init(sessionPath: IrisSessionPath, onDeleted: @escaping () -> Void = {}) {
        _viewModel = State(wrappedValue: IrisChatViewModel(sessionPath: sessionPath))
        self.onDeleted = onDeleted
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: .m) {
                        ForEach(viewModel.messages) { message in
                            MessageRow(message: message)
                        }
                    }
                    .padding(.l)
                    Spacer()
                        .frame(height: 1)
                        .id("bottom")
                }
                .defaultScrollAnchor(.bottom)
                .onChange(of: viewModel.messages.count) {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.messages.last) {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            InputBar(text: $viewModel.inputText, onSend: { viewModel.sendMessage() })
        }
        .navigationTitle(viewModel.sessionTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Chat", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Chat", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deleteSession() {
                        onDeleted()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this chat? This action cannot be undone.")
        }
        .task { await viewModel.loadMessages() }
        .task { await viewModel.connectWebSocket() }
        .onDisappear { Task {
            await viewModel.disconnect()
        } }
        .loadingIndicator(isLoading: $viewModel.isLoading)
        .alert(isPresented: viewModel.showError, error: viewModel.error, actions: {})
    }
}


private struct MessageRow: View {
    let message: IrisMessageResponseDTO

    var body: some View {
        if isUser {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: .s) {
                    ForEach(message.content, id: \.id) { block in
                        if let text = block.textContent {
                            ArtemisMarkdownView(string: text)
                                .padding(.m + .xs)
                                .background(Color.Artemis.reactionCapsuleColor)
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .frame(maxWidth: 300, alignment: .trailing)
            }
        } else {
            VStack(alignment: .leading, spacing: .s) {
                ForEach(message.content, id: \.id) { block in
                    if let text = block.textContent {
                        ArtemisMarkdownView(string: text)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var isUser: Bool {
        message.sender == .user
    }
}

private struct InputBar: View {
    @Binding var text: String
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: .m) {
            TextField("Ask Iris...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .imageScale(.large)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, .l)
        .padding(.vertical, .m)
    }
}
