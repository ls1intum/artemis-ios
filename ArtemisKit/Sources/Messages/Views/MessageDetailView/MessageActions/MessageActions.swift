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

struct MessageActionsBar: View {
    @ObservedObject var viewModel: ConversationViewModel
    @Binding var message: DataState<BaseMessage>
    let conversationPath: ConversationPath?

    var body: some View {
        MessageActions(viewModel: viewModel, message: $message, conversationPath: conversationPath)
            .environment(\.actionsDisplayMode, .bar)
    }
}

struct MessageActionsMenu: View {
    @ObservedObject var viewModel: ConversationViewModel
    @Binding var message: DataState<BaseMessage>
    let conversationPath: ConversationPath?

    var body: some View {
        MessageActions(viewModel: viewModel, message: $message, conversationPath: conversationPath)
            .background(.bar, in: .rect(cornerRadius: 10))
            .fontWeight(.semibold)
    }
}

private struct MessageActions: View {
    @ObservedObject var viewModel: ConversationViewModel
    @Binding var message: DataState<BaseMessage>
    let conversationPath: ConversationPath?

    var body: some View {
        MenuGroup {
            HorizontalMenuGroup {
                ReplyButton(viewModel: viewModel, message: $message, conversationPath: conversationPath)
                ForwardButton(viewModel: viewModel, message: $message)
                BookmarkButton(viewModel: viewModel, message: $message)
            }
            CopyTextButton(viewModel: viewModel, message: $message)
            PinButton(viewModel: viewModel, message: $message)
            MarkResolvingButton(viewModel: viewModel, message: $message)
            EditDeleteSection(viewModel: viewModel, message: $message)
        }
        .lineLimit(1)
        .font(.title3)
    }

    struct ReplyButton: View {
        @EnvironmentObject var navigationController: NavigationController
        @ObservedObject var viewModel: ConversationViewModel
        @Binding var message: DataState<BaseMessage>
        let conversationPath: ConversationPath?

        var body: some View {
            if message.value is Message,
               let conversationPath {
                Button(R.string.localizable.replyInThread(), systemImage: "arrowshape.turn.up.left") {
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

    struct ForwardButton: View {
        @EnvironmentObject var navigationController: NavigationController
        @State private var viewModel: MessageActionsViewModel

        init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>) {
            _viewModel = State(initialValue: MessageActionsViewModel(conversationViewModel: viewModel, message: message))
        }

        var body: some View {
            Button(R.string.localizable.forwardMessageShort(), systemImage: "arrowshape.turn.up.right") {
                viewModel.showForwardSheet = true
            }
            .sheet(isPresented: $viewModel.showForwardSheet) {
                viewModel.conversationViewModel.selectedMessageId = nil
            } content: {
                ForwardMessageView(viewModel: viewModel)
                    .font(nil)
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
            if message.value?.isBookmarked ?? false {
                Button(R.string.localizable.removeBookmark(), systemImage: "bookmark.slash") {
                    viewModel.toggleBookmark()
                }
            } else {
                Button(R.string.localizable.addBookmark(), systemImage: "bookmark") {
                    viewModel.toggleBookmark()
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

    struct PinButton: View {
        @State private var viewModel: MessageActionsViewModel
        @Binding private var message: DataState<BaseMessage>

        init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>) {
            _viewModel = State(initialValue: MessageActionsViewModel(conversationViewModel: viewModel, message: message))
            _message = message
        }

        var body: some View {
            if viewModel.canPin {
                if (message.value as? Message)?.displayPriority == .pinned {
                    Button(R.string.localizable.unpinMessage(), systemImage: "pin.slash", action: viewModel.togglePinned)
                } else {
                    Button(R.string.localizable.pinMessage(), systemImage: "pin", action: viewModel.togglePinned)
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
            if isAbleToMarkResolving {
                if (message.value as? AnswerMessage)?.resolvesPost ?? false {
                    Button(R.string.localizable.unmarkAsResolving(), systemImage: "xmark", action: toggleResolved)
                } else {
                    Button(R.string.localizable.markAsResolving(), systemImage: "checkmark", action: toggleResolved)
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

private struct MessageActionsStyleModifier: ViewModifier {
    @Environment(\.actionsDisplayMode) private var displayMode

    func body(content: Content) -> some View {
        if displayMode == .menu {
            content
                .symbolVariant(.fill)
                .labelStyle(ContextMenuLabelStyle())
                .buttonStyle(.plain)
        } else {
            content
        }
    }
}

private struct ContextMenuLabelStyle: LabelStyle {
    @Environment(\.actionsDisplayMode) var displayMode

    var layout: AnyLayout {
        if displayMode == .menuCompact {
            AnyLayout(VStackLayout())
        } else {
            AnyLayout(HStackLayout())
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        layout {
            if displayMode == .menuCompact {
                configuration.icon.frame(height: 40)
                configuration.title.font(.callout)
            } else {
                configuration.title
                Spacer()
                configuration.icon
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
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

// MARK: - Layout
private enum ActionsDisplayMode {
    case menu, menuCompact, bar
}

private struct HorizontalMenuGroup<Content: View>: View {
    @Environment(\.actionsDisplayMode) private var displayMode
    @ViewBuilder var content: Content

    var isMenu: Bool { displayMode == .menu }

    var body: some View {
        HStack {
            Group(subviews: content) { subviews in
                ForEach(subviews.dropLast()) { subview in
                    subview
                        .frame(maxWidth: isMenu ? .infinity : nil)
                    Divider()
                }
                subviews.last
                    .frame(maxWidth: isMenu ? .infinity : nil)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .environment(\.actionsDisplayMode, isMenu ? .menuCompact : displayMode)
    }
}

private struct MenuGroup<Content: View>: View {
    @Environment(\.actionsDisplayMode) private var displayMode
    @ViewBuilder var content: Content

    var layout: AnyLayout {
        if displayMode == .menu {
            AnyLayout(VStackLayout(spacing: 0))
        } else {
            AnyLayout(HStackLayout(spacing: 10))
        }
    }

    var body: some View {
        layout {
            Group(subviews: content) { subviews in
                ForEach(subviews.dropLast()) { subview in
                    subview
                    Divider()
                }
                subviews.last
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .modifier(MessageActionsStyleModifier())
    }
}

// MARK: Environment+ActionsDisplayMode

private enum ActionsDisplayModeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ActionsDisplayMode = .menu
}

private extension EnvironmentValues {
    var actionsDisplayMode: ActionsDisplayMode {
        get {
            self[ActionsDisplayModeEnvironmentKey.self]
        }
        set {
            self[ActionsDisplayModeEnvironmentKey.self] = newValue
        }
    }
}
