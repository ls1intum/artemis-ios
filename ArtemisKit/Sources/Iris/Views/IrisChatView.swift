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
    @State private var viewportHeight: CGFloat = 0
    @State private var bottomSpacerHeight: CGFloat = 0

    private let onDeleted: () -> Void

    init(sessionPath: IrisSessionPath, onDeleted: @escaping () -> Void = {}) {
        _viewModel = State(wrappedValue: IrisChatViewModel(sessionPath: sessionPath))
        self.onDeleted = onDeleted
    }

    var body: some View {
        DataStateView(data: $viewModel.messages) {
            await viewModel.loadMessages()
        } content: { messages in
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        if messages.isEmpty {
                            EmptyChatView()
                                .containerRelativeFrame(.vertical)
                        } else {
                            LazyVStack(alignment: .leading, spacing: .m) {
                                ForEach(messages) { message in
                                    MessageRow(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.l)
                        }
                        Color.clear.frame(height: bottomSpacerHeight)
                    }
                    .defaultScrollAnchor(.bottom)
                    .background {
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { viewportHeight = geo.size.height }
                                .onChange(of: geo.size.height) { _, newValue in
                                    viewportHeight = newValue
                                }
                        }
                    }
                    .onChange(of: messages.count) {
                        guard let last = messages.last, last.sender == .user else { return }
                        withAnimation {
                            bottomSpacerHeight = viewportHeight
                            proxy.scrollTo(last.id, anchor: .top)
                        }
                    }
                }
                InputBar(text: $viewModel.inputText, onSend: { viewModel.sendMessage() })
            }
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
                .confirmationDialog(
                    "Are you sure you want to delete this chat? This action cannot be undone.",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        Task {
                            if await viewModel.deleteSession() {
                                onDeleted()
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .task { await viewModel.loadMessages() }
        .task { await viewModel.subscribeToWebsocket() }
        .onDisappear { Task {
            await viewModel.disconnect()
        }
        }
        .alert(isPresented: viewModel.showError, error: viewModel.error, actions: {})
    }
}

private struct MessageRow: View {
    let message: IrisMessageResponseDTO

    private var isUser: Bool {
        message.sender == .user
    }

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
}

private struct EmptyChatView: View {
    var body: some View {
        VStack(spacing: .m) {
            Image("iris-colored", bundle: .module)
                  .resizable()
                  .scaledToFit()
                  .frame(width: 80, height: 80)
                  .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            Text("How can I help you today?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
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
