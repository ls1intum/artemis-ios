//
//  MessageActions.swift
//
//
//  Created by Sven Andabaka on 08.04.23.
//

import Common
import EmojiPicker
import Navigation
import SharedModels
import Smile
import SwiftUI
import UserStore

struct MessageActions: View {
    @ObservedObject var viewModel: ConversationViewModel
    @Binding var message: DataState<BaseMessage>
    let conversationPath: ConversationPath?

    var body: some View {
        Group {
            ReplyInThreadButton(viewModel: viewModel, message: $message, conversationPath: conversationPath)
            CopyTextButton(message: $message)
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
                    } else {
                        viewModel.presentError(userFacingError: UserFacingError(title: R.string.localizable.detailViewCantBeOpened()))
                    }
                }
            }
        }
    }

    struct CopyTextButton: View {
        @EnvironmentObject var navController: NavigationController
        @Binding var message: DataState<BaseMessage>
        @State private var showSuccess = false

        var body: some View {
            Button(R.string.localizable.copyText(), systemImage: "doc.on.doc") {
                UIPasteboard.general.string = message.value?.content
                if !navController.tabPath.isEmpty && message.value is Message {
                    showSuccess = true
                }
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

    struct EditDeleteSection: View {
        @EnvironmentObject var navigationController: NavigationController
        @ObservedObject var viewModel: ConversationViewModel
        @Binding var message: DataState<BaseMessage>

        @State private var showDeleteAlert = false
        @State private var showEditSheet = false

        var isAbleToEditDelete: Bool {
            guard let message = message.value else {
                return false
            }

            if message.isCurrentUserAuthor {
                return true
            }

            guard let channel = viewModel.conversation.baseConversation as? Channel else {
                return false
            }
            if channel.hasChannelModerationRights ?? false && message is Message {
                return true
            }

            return false
        }

        var body: some View {
            Group {
                if isAbleToEditDelete {
                    Divider()

                    Button(R.string.localizable.editMessage(), systemImage: "pencil") {
                        viewModel.isPerformingMessageAction = true
                        showEditSheet = true
                    }
                    .sheet(isPresented: $showEditSheet) {
                        viewModel.isPerformingMessageAction = false
                        viewModel.selectedMessageId = nil
                    } content: {
                        editMessage
                            .font(nil)
                    }

                    Button(R.string.localizable.deleteMessage(), systemImage: "trash", role: .destructive) {
                        viewModel.isPerformingMessageAction = true
                        showDeleteAlert = true
                    }
                    .alert(R.string.localizable.confirmDeletionTitle(), isPresented: $showDeleteAlert) {
                        Button(R.string.localizable.confirm(), role: .destructive) {
                            viewModel.isLoading = true
                            Task(priority: .userInitiated) {
                                let success: Bool
                                let tempMessage = message.value
                                if message.value is AnswerMessage {
                                    success = await viewModel.deleteAnswerMessage(messageId: message.value?.id)
                                } else {
                                    success = await viewModel.deleteMessage(messageId: message.value?.id)
                                }
                                viewModel.isLoading = false
                                viewModel.isPerformingMessageAction = false
                                viewModel.selectedMessageId = nil
                                if success {
                                    // if we deleted a Message and are in the MessageDetailView we pop it
                                    if navigationController.outerPath.count == 3 && tempMessage is Message {
                                        navigationController.outerPath.removeLast()
                                    }
                                }
                            }
                        }
                        Button(R.string.localizable.cancel(), role: .cancel) {
                            viewModel.isPerformingMessageAction = false
                            viewModel.selectedMessageId = nil
                        }
                    }
                }
            }
        }

        var editMessage: some View {
            NavigationView {
                Group {
                    if let message = message.value as? Message {
                        SendMessageView(
                            viewModel: SendMessageViewModel(
                                course: viewModel.course,
                                conversation: viewModel.conversation,
                                configuration: .editMessage(message, { self.showEditSheet = false }),
                                delegate: SendMessageViewModelDelegate(viewModel)
                            )
                        )
                    } else if let answerMessage = message.value as? AnswerMessage {
                        SendMessageView(
                            viewModel: SendMessageViewModel(
                                course: viewModel.course,
                                conversation: viewModel.conversation,
                                configuration: .editAnswerMessage(answerMessage, { self.showEditSheet = false }),
                                delegate: SendMessageViewModelDelegate(viewModel)
                            )
                        )
                    } else {
                        Text(R.string.localizable.loading())
                    }
                }
                .navigationTitle(R.string.localizable.editMessage())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(R.string.localizable.cancel()) {
                            showEditSheet = false
                        }
                    }
                }
            }
            .fontWeight(.regular)
            .presentationDetents([.height(200), .medium])
        }
    }

    struct PinButton: View {
        @EnvironmentObject var navigationController: NavigationController
        @ObservedObject var viewModel: ConversationViewModel
        @Binding var message: DataState<BaseMessage>

        var isAbleToPin: Bool {
            guard let message = message.value, message is Message else {
                return false
            }

            // Channel: Only Moderators can pin
            let isModerator = (viewModel.conversation.baseConversation as? Channel)?.isChannelModerator ?? false
            if viewModel.conversation.baseConversation is Channel && !isModerator {
                return false
            }

            // Group Chat: Only Creator can pin
            let isCreator = viewModel.conversation.baseConversation.isCreator ?? false
            if viewModel.conversation.baseConversation is GroupChat && !isCreator {
                return false
            }

            return true
        }

        var body: some View {
            Group {
                if isAbleToPin {
                    Divider()

                    if (message.value as? Message)?.displayPriority == .pinned {
                        Button(R.string.localizable.unpinMessage(), systemImage: "pin.slash", action: togglePinned)
                    } else {
                        Button(R.string.localizable.pinMessage(), systemImage: "pin", action: togglePinned)
                    }
                }
            }
        }

        func togglePinned() {
            guard let message = message.value as? Message else { return }
            viewModel.isPerformingMessageAction = true
            Task {
                let result = await viewModel.togglePinned(for: message)
                let oldRole = message.authorRole
                if var newMessageResult = result.value as? Message {
                    newMessageResult.authorRole = oldRole
                    self.$message.wrappedValue = .done(response: newMessageResult)
                    viewModel.isPerformingMessageAction = false
                    viewModel.selectedMessageId = nil
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
            viewModel.isPerformingMessageAction = true
            Task {
                if await viewModel.toggleResolving(for: message) {
                    viewModel.isPerformingMessageAction = false
                    viewModel.selectedMessageId = nil
                }
            }
        }
    }
}

struct MessageReactionsPopover: View {
    @ObservedObject var viewModel: ConversationViewModel
    @Binding var message: DataState<BaseMessage>
    @State var reactionsViewModel: ReactionsViewModel

    init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>, conversationPath: ConversationPath?) {
        self.viewModel = viewModel
        self._message = message
        self._reactionsViewModel = State(initialValue: ReactionsViewModel(conversationViewModel: viewModel, message: message))
    }

    var body: some View {
        HStack(spacing: .m) {
            EmojiTextButton(viewModel: reactionsViewModel, emoji: "😂")
            EmojiTextButton(viewModel: reactionsViewModel, emoji: "👍")
            EmojiTextButton(viewModel: reactionsViewModel, emoji: "➕")
            EmojiTextButton(viewModel: reactionsViewModel, emoji: "🚀")
            EmojiPickerButton(viewModel: reactionsViewModel)
        }
        .padding(.l)
        .buttonStyle(.plain)
        .font(.headline)
        .symbolVariant(.fill)
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
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

private struct EmojiTextButton: View {

    @Environment(\.dismiss) var dismiss

    var viewModel: ReactionsViewModel

    let emoji: String

    var body: some View {
        Text("\(emoji)")
            .font(.title3)
            .foregroundColor(Color.Artemis.primaryLabel)
            .frame(width: .mediumImage, height: .mediumImage)
            .padding(.s)
            .background(
                Capsule().fill(Color.Artemis.reactionCapsuleColor)
            )
            .onTapGesture {
                if let emojiId = Smile.alias(emoji: emoji) {
                    Task {
                        await viewModel.addReaction(emojiId: emojiId)
                        dismiss()
                    }
                }
            }
    }
}

private struct EmojiPickerButton: View {

    @Environment(\.dismiss) var dismiss

    var viewModel: ReactionsViewModel

    @State private var showEmojiPicker = false
    @State var selectedEmoji: Emoji?

    var body: some View {
        Button {
            showEmojiPicker = true
        } label: {
            Image("face-smile", bundle: .module)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.Artemis.secondaryLabel)
                .frame(width: .smallImage, height: .smallImage)
                .padding(.l)
                .background(Capsule().fill(Color.Artemis.reactionCapsuleColor))
        }
        .sheet(isPresented: $showEmojiPicker) {
            NavigationView {
                EmojiPickerView(selectedEmoji: $selectedEmoji, selectedColor: Color.Artemis.artemisBlue)
                    .navigationTitle(R.string.localizable.emojis())
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onChange(of: selectedEmoji) { _, newEmoji in
            if let newEmoji,
               let emojiId = Smile.alias(emoji: newEmoji.value) {
                Task {
                    await viewModel.addReaction(emojiId: emojiId)
                    selectedEmoji = nil
                    dismiss()
                }
            }
        }
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
