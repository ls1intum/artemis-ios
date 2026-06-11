//
//  IrisChatView.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 25.05.26.
//

import ArtemisMarkdown
import DesignLibrary
import Navigation
import SwiftUI
import UIKit

struct IrisChatView: View {
    @State private var viewModel: IrisChatViewModel
    @State private var showDeleteConfirmation = false
    @State private var bottomSpacerShown = false
    @State private var showScrollToBottom = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.scenePhase) private var scenePhase

    private let onDeleted: () -> Void
    private let onTitleChange: (String) -> Void

    init(sessionPath: IrisSessionPath,
         onDeleted: @escaping () -> Void = {},
         onTitleChange: @escaping (String) -> Void = { _ in }) {
        _viewModel = State(wrappedValue: IrisChatViewModel(sessionPath: sessionPath))
        self.onDeleted = onDeleted
        self.onTitleChange = onTitleChange
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
                                    MessageRow(message: message, viewModel: viewModel)
                                        .id(message.id)
                                }
                                if viewModel.isAwaitingResponse {
                                    LoadingStageRow(stage: viewModel.currentStage)
                                        .id("loadingStageRow")
                                } else if messages.last?.sender == .llm {
                                    DisclaimerView()
                                        .id("disclaimer")
                                }
                            }
                            .padding(.l)
                        }
                        if bottomSpacerShown {
                            Color.clear.containerRelativeFrame(.vertical)
                        }
                    }
                    .defaultScrollAnchor(.bottom)
                    .onScrollGeometryChange(for: Bool.self) { geometry in
                        let distanceFromBottom = geometry.contentSize.height
                            - geometry.contentOffset.y
                            - geometry.containerSize.height
                        return distanceFromBottom > 120
                    } action: { _, isAway in
                        withAnimation(.easeInOut(duration: 0.2)) { showScrollToBottom = isAway }
                    }
                    .onChange(of: messages.count) {
                        guard let last = messages.last, last.sender == .user else { return }
                        bottomSpacerShown = true
                        Task { @MainActor in
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .top)
                            }
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if showScrollToBottom {
                            ScrollToBottomButton {
                                withAnimation {
                                    if viewModel.isAwaitingResponse {
                                        proxy.scrollTo("loadingStageRow", anchor: .bottom)
                                    } else if messages.last?.sender == .llm {
                                        proxy.scrollTo("disclaimer", anchor: .bottom)
                                    } else if let id = messages.last?.id {
                                        proxy.scrollTo(id, anchor: .bottom)
                                    }
                                }
                            }
                            .padding(.bottom, .m)
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
                InputBar(text: $viewModel.inputText, isFocused: $isInputFocused, onSend: {
                    viewModel.sendMessage()
                    isInputFocused = false
                })
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
                        Label(R.string.localizable.deleteChat(), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .confirmationDialog(
                    R.string.localizable.deleteChatConfirmationMessage(),
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(R.string.localizable.delete(), role: .destructive) {
                        Task {
                            if await viewModel.deleteSession() {
                                onDeleted()
                            }
                        }
                    }
                    Button(R.string.localizable.cancel(), role: .cancel) {}
                }
            }
        }
        .task { await viewModel.loadMessages() }
        .task { await viewModel.subscribeToWebsocket() }
        .onChange(of: scenePhase) { _, newPhase in
            // Iris' reply arrives only once over the STOMP topic, which iOS tears
            // down on backgrounding. STOMP doesn't replay messages published while
            // we were disconnected, so a reply that lands in the background never
            // reaches the live stream. Re-fetch the persisted messages on return to
            // the foreground to catch up (upsert dedupes against the live stream).
            if newPhase == .active {
                Task { await viewModel.refreshMessages() }
            }
        }
        .onChange(of: viewModel.sessionTitle) { _, newTitle in
            if let newTitle { onTitleChange(newTitle) }
        }
        .onDisappear { Task {
            await viewModel.disconnect()
        }
        }
        .alert(isPresented: viewModel.showError, error: viewModel.error, actions: {})
    }
}

private struct MessageRow: View {
    let message: IrisMessageResponseDTO
    let viewModel: IrisChatViewModel

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
                if message.id != nil {
                    IrisMessageActionBar(message: message, viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct IrisMessageActionBar: View {
    let message: IrisMessageResponseDTO
    let viewModel: IrisChatViewModel
    @State private var didCopy = false

    private var plainText: String {
        message.content.compactMap(\.textContent).joined(separator: "\n\n")
    }

    var body: some View {
        HStack(spacing: .l) {
            Button(R.string.localizable.copyText(),
                   systemImage: didCopy ? "checkmark" : "doc.on.doc") {
                UIPasteboard.general.string = plainText
                didCopy = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { didCopy = false }
            }
            .labelStyle(.iconOnly)

            ShareLink(item: plainText) {
                Label(R.string.localizable.shareMessage(), systemImage: "square.and.arrow.up")
            }
            .labelStyle(.iconOnly)

            Button(R.string.localizable.rateHelpful(),
                   systemImage: message.helpful == true ? "hand.thumbsup.fill" : "hand.thumbsup") {
                if message.helpful != true, let id = message.id {
                    viewModel.rateMessage(messageId: id, helpful: true)
                }
            }
            .labelStyle(.iconOnly)

            Button(R.string.localizable.rateUnhelpful(),
                   systemImage: message.helpful == false ? "hand.thumbsdown.fill" : "hand.thumbsdown") {
                if message.helpful != false, let id = message.id {
                    viewModel.rateMessage(messageId: id, helpful: false)
                }
            }
            .labelStyle(.iconOnly)
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
        .padding(.top, .s)
    }
}

private struct DisclaimerView: View {
    var body: some View {
        Text(R.string.localizable.irisDisclaimer())
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, .s)
    }
}

private struct ScrollToBottomButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.down")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.m + .s)
                .background(.regularMaterial, in: .circle)
                .overlay(Circle().stroke(Color.primary.opacity(0.1)))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .accessibilityLabel(R.string.localizable.scrollToBottom())
    }
}

private struct LoadingStageRow: View {
    let stage: IrisStageDTO?

    private var label: String {
        stage?.chatMessage
            ?? stage?.message
            ?? stage?.name
            ?? R.string.localizable.thinking()
    }

    var body: some View {
        HStack(spacing: .m) {
            ProgressView()
                .controlSize(.small)
            Text(label)
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity)
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
            Text(R.string.localizable.emptyChatTitle())
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct InputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: .m) {
            TextField(R.string.localizable.askIrisPlaceholder(), text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .focused($isFocused)

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
