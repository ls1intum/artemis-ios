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
    @State private var contextViewModel: IrisContextSelectionViewModel
    @State private var showDeleteConfirmation = false
    @State private var isContextSelectionPresented = false
    @State private var bottomSpacerShown = false
    @FocusState private var isInputFocused: Bool

    private let courseId: Int
    private let onDeleted: () -> Void
    private let onTitleChange: (String) -> Void
    private let onContextChange: (SessionContext) -> Void

    init(sessionPath: IrisSessionPath,
         session: IrisSessionDTO?,
         onDeleted: @escaping () -> Void = {},
         onTitleChange: @escaping (String) -> Void = { _ in },
         onContextChange: @escaping (SessionContext) -> Void = { _ in }) {
        _viewModel = State(wrappedValue: IrisChatViewModel(sessionPath: sessionPath, session: session))
        _contextViewModel = State(wrappedValue: IrisContextSelectionViewModel())
        self.courseId = sessionPath.courseId
        self.onDeleted = onDeleted
        self.onTitleChange = onTitleChange
        self.onContextChange = onContextChange
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
                                    MessageRow(message: message, courseId: courseId)
                                        .id(message.id)
                                }
                                if viewModel.isAwaitingResponse {
                                    LoadingStageRow(stage: viewModel.currentStage)
                                        .id("loadingStageRow")
                                }
                            }
                            .padding(.l)
                        }
                        if bottomSpacerShown {
                            Color.clear.containerRelativeFrame(.vertical)
                        }
                    }
                    .defaultScrollAnchor(.bottom)
                    .onChange(of: messages.count) {
                        guard let last = messages.last, last.sender == .user else { return }
                        bottomSpacerShown = true
                        Task { @MainActor in
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .top)
                            }
                        }
                    }
                }
                InputBar(
                    text: $viewModel.inputText,
                    isFocused: $isInputFocused,
                    isContextPresented: $isContextSelectionPresented,
                    courseId: courseId,
                    contextViewModel: contextViewModel,
                    currentSelection: viewModel.displayedChipContext,
                    chipTitle: viewModel.displayedChipContext.map { $0.entityName ?? R.string.localizable.untitled() },
                    onSend: {
                        viewModel.sendMessage()
                        isInputFocused = false
                    },
                    onPlusTapped: {
                        isContextSelectionPresented = true
                    },
                    onChipRemoved: {
                        viewModel.clearPendingSelection()
                    },
                    onContextSelected: { selection in
                        viewModel.commitPendingSelection(selection)
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
        .onChange(of: viewModel.sessionTitle) { _, newTitle in
            if let newTitle { onTitleChange(newTitle) }
        }
        .onChange(of: viewModel.committedContext) { _, newContext in
            if let newContext { onContextChange(newContext) }
        }
        .onDisappear { Task {
            await viewModel.disconnect()
        }
        }
        .alert(isPresented: viewModel.showError, error: viewModel.error, actions: {})
    }
}

// MARK: Message Row

private struct MessageRow: View {
    let message: IrisMessageResponseDTO
    let courseId: Int

    private var isUser: Bool {
        message.sender == .user
    }

    private var isCtxSwap: Bool {
        message.sender == .ctxswap
    }

    var body: some View {
        if isCtxSwap {
            if let contextSwitch = message.contextSwitch {
                IrisContextSwitchDivider(info: contextSwitch, courseId: courseId)
            }
        } else if isUser {
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

// MARK: Loading Stage

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

// MARK: Empty State

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

// MARK: Input Bar

private struct InputBar: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    @Binding var isContextPresented: Bool
    let courseId: Int
    let contextViewModel: IrisContextSelectionViewModel
    let currentSelection: SessionContext?
    let chipTitle: String?
    let onSend: () -> Void
    let onPlusTapped: () -> Void
    let onChipRemoved: () -> Void
    let onContextSelected: (SessionContext) -> Void

    private var isSendDisabled: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: .m) {
            TextField(R.string.localizable.askIrisPlaceholder(), text: $text, axis: .vertical)
                .lineLimit(1...5)
                .focused($isFocused)

            HStack(spacing: .m) {
                Button(action: onPlusTapped) {
                    Image(systemName: "plus")
                        .imageScale(.large)
                }
                .popover(isPresented: $isContextPresented,
                         attachmentAnchor: .point(.top),
                         arrowEdge: .bottom) {
                    IrisContextSelectionView(viewModel: contextViewModel,
                                             courseId: courseId,
                                             currentSelection: currentSelection,
                                             onSet: onContextSelected)
                        .modifier(ContextSelectionPresentation(isRegular: horizontalSizeClass == .regular))
                }

                if let chipTitle {
                    IrisContextChip(title: chipTitle, onTap: onPlusTapped, onRemove: onChipRemoved)
                }

                Spacer()

                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .imageScale(.large)
                }
                .disabled(isSendDisabled)
            }
        }
        .padding(.m + .xs)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.Artemis.cardBorderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, .l)
        .padding(.vertical, .m)
    }
}

// MARK: Context Chip

private struct IrisContextChip: View {
    let title: String
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: .s) {
            Text(title)
                .font(.footnote)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .m)
        .padding(.vertical, .s)
        .background(Color.Artemis.reactionCapsuleColor, in: Capsule())
    }
}

// MARK: Context Selection Presentation

/// iPhone keeps the familiar resizable sheet (the `.popover` adapts to a sheet at
/// compact width); iPad shows a fixed-size popover anchored to the `+`. 
private struct ContextSelectionPresentation: ViewModifier {
    let isRegular: Bool

    func body(content: Content) -> some View {
        if isRegular {
            content.frame(minWidth: 360, minHeight: 480)
        } else {
            content.presentationDetents([.medium, .large])
        }
    }
}
