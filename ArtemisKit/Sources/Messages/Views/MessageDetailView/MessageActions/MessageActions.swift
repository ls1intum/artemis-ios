//
//  MessageActions.swift
//
//
//  Created by Sven Andabaka on 08.04.23.
//

import Common
import Navigation
import SharedModels
import SwiftUI
import UserStore

struct MessageActions: View {
    @ObservedObject var viewModel: ConversationViewModel
    @Binding var message: DataState<BaseMessage>
    let conversationPath: ConversationPath?

    var body: some View {
        Group {
            ReplyInThreadButton(viewModel: viewModel, message: $message, conversationPath: conversationPath)
            CopyTextButton(viewModel: viewModel, message: $message)
            BookmarkButton(viewModel: viewModel, message: $message)
            PinButton(viewModel: viewModel, message: $message)
            MarkResolvingButton(viewModel: viewModel, message: $message)
            EditDeleteSection(viewModel: viewModel, message: $message)
        }
        .lineLimit(1)
        .font(.title3)
    }

    struct ReplyInThreadButton: View {
        @EnvironmentObject var navigationController: NavigationController
        @ObservedObject var viewModel: ConversationViewModel
        @Binding var message: DataState<BaseMessage>
        let conversationPath: ConversationPath?

        var body: some View {
            if message.value is Message,
               let conversationPath {
                Button(R.string.localizable.replyInThread(), systemImage: "text.bubble") {
                    if let messagePath = MessagePath(
                        message: $message,
                        conversationPath: conversationPath,
                        conversationViewModel: viewModel
                    ) {
                        navigationController.tabPath.append(messagePath)
                        viewModel.selectedMessageId = nil
                    } else {
                        viewModel.presentError(userFacingError: UserFacingError(title: R.string.localizable.detailViewCantBeOpened()))
                    }
                }
            }
        }
    }

    struct CopyTextButton: View {
        @EnvironmentObject var navController: NavigationController
        @ObservedObject var viewModel: ConversationViewModel
        @Binding var message: DataState<BaseMessage>
        @State private var showSuccess = false

        var body: some View {
            Button(R.string.localizable.copyText(), systemImage: "doc.on.doc") {
                UIPasteboard.general.string = message.value?.content
                if !navController.tabPath.isEmpty && message.value is Message {
                    showSuccess = true
                }
                viewModel.selectedMessageId = nil
            }
            .opacity(showSuccess ? 0 : 1)
            .overlay {
                if showSuccess {
                    Label("Copied", systemImage: "checkmark.circle.fill")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                        .transition(.scale)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccess = false
                            }
                        }
                }
            }
            .animation(.spring(), value: showSuccess)
        }
    }

    struct BookmarkButton: View {
        @State private var viewModel: MessageActionsViewModel
        @Binding private var message: DataState<BaseMessage>

        init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>) {
            _viewModel = State(initialValue: MessageActionsViewModel(conversationViewModel: viewModel, message: message))
            _message = message
        }

        var body: some View {
            Group {
                Divider()
                if message.value?.isBookmarked ?? false {
                    Button("Remove bookmark", systemImage: "bookmark.slash") {
                        viewModel.toggleBookmark()
                    }
                } else {
                    Button("Add bookmark", systemImage: "bookmark") {
                        viewModel.toggleBookmark()
                    }
                }
            }
        }
    }

    struct EditDeleteSection: View {
        @EnvironmentObject var navigationController: NavigationController
        @State private var viewModel: MessageActionsViewModel

        init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>) {
            _viewModel = State(initialValue: MessageActionsViewModel(conversationViewModel: viewModel, message: message))
        }

        var body: some View {
            Group {
                if viewModel.canEdit || viewModel.canDelete {
                    Divider()
                }
                if viewModel.canEdit {
                    Button(R.string.localizable.editMessage(), systemImage: "pencil") {
                        viewModel.showEditSheet = true
                    }
                    .sheet(isPresented: $viewModel.showEditSheet) {
                        viewModel.conversationViewModel.selectedMessageId = nil
                    } content: {
                        EditMessageView(viewModel: viewModel)
                            .font(nil)
                    }
                }
                if viewModel.canDelete {
                    Button(R.string.localizable.deleteMessage(), systemImage: "trash", role: .destructive) {
                        viewModel.showDeleteAlert = true
                    }
                    .foregroundStyle(.red)
                    .alert(R.string.localizable.confirmDeletionTitle(), isPresented: $viewModel.showDeleteAlert) {
                        Button(R.string.localizable.confirm(), role: .destructive) {
                            viewModel.deleteMessage(navController: navigationController)
                        }
                        Button(R.string.localizable.cancel(), role: .cancel) {
                            viewModel.conversationViewModel.selectedMessageId = nil
                        }
                    }
                }
            }
        }
    }

    struct PinButton: View {
        @State private var viewModel: MessageActionsViewModel
        @Binding private var message: DataState<BaseMessage>

        init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>) {
            _viewModel = State(initialValue: MessageActionsViewModel(conversationViewModel: viewModel, message: message))
            _message = message
        }

        var body: some View {
            Group {
                if viewModel.canPin {
                    Divider()

                    if (message.value as? Message)?.displayPriority == .pinned {
                        Button(R.string.localizable.unpinMessage(), systemImage: "pin.slash", action: viewModel.togglePinned)
                    } else {
                        Button(R.string.localizable.pinMessage(), systemImage: "pin", action: viewModel.togglePinned)
                    }
                }
            }
        }
    }

    struct MarkResolvingButton: View {
        @EnvironmentObject var navigationController: NavigationController
        @ObservedObject var viewModel: ConversationViewModel
        @Binding var message: DataState<BaseMessage>

        @Environment(\.isOriginalMessageAuthor) var isOriginalMessageAuthor

        var isAbleToMarkResolving: Bool {
            guard let message = message.value, message is AnswerMessage else {
                return false
            }
            guard viewModel.conversation.baseConversation is Channel else {
                return false
            }

            // Author as well as Tutors and higher level can mark as resolving
            if viewModel.course.isAtLeastTutorInCourse || isOriginalMessageAuthor {
                return true
            }

            return false
        }

        var body: some View {
            Group {
                if isAbleToMarkResolving {
                    Divider()

                    if (message.value as? AnswerMessage)?.resolvesPost ?? false {
                        Button(R.string.localizable.unmarkAsResolving(), systemImage: "xmark", action: toggleResolved)
                    } else {
                        Button(R.string.localizable.markAsResolving(), systemImage: "checkmark", action: toggleResolved)
                    }
                }
            }
        }

        func toggleResolved() {
            guard let message = message.value as? AnswerMessage else { return }
            Task {
                if await viewModel.toggleResolving(for: message) {
                    viewModel.selectedMessageId = nil
                }
            }
        }
    }
}

struct MessageActionsMenu: View {
    @ObservedObject var viewModel: ConversationViewModel
    @Binding var message: DataState<BaseMessage>
    let conversationPath: ConversationPath?

    init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>, conversationPath: ConversationPath?) {
        self.viewModel = viewModel
        self._message = message
        self.conversationPath = conversationPath
    }

    var body: some View {
        VStack {
            MessageActions(viewModel: viewModel, message: $message, conversationPath: conversationPath)
        }
        .padding(.vertical, .s)
        .background(.bar, in: .rect(cornerRadius: 10))
        .fontWeight(.semibold)
        .symbolVariant(.fill)
        .labelStyle(ContextMenuLabelStyle())
        .buttonStyle(.plain)
        .loadingIndicator(isLoading: $viewModel.isLoading)
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }
}

private struct ContextMenuLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            Spacer()
            configuration.icon
        }
        .padding(.horizontal)
        .padding(.vertical, .s)
        .contentShape(.rect)
    }
}

// MARK: - Environment+OriginalPostAuthor

private enum OriginalPostAuthorEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isOriginalMessageAuthor: Bool {
        get {
            self[OriginalPostAuthorEnvironmentKey.self]
        }
        set {
            self[OriginalPostAuthorEnvironmentKey.self] = newValue
        }
    }
}
