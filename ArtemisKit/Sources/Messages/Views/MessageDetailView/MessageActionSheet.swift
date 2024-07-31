//
//  SwiftUIView.swift
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
            EditDeleteSection(viewModel: viewModel, message: $message)
        }
        .environment(\.allowAutoDismiss, false)
        .lineLimit(1)
        .font(.title3.bold())
    }

    struct ReplyInThreadButton: View {
        @EnvironmentObject var navigationController: NavigationController
        @Environment(\.dismiss) var dismiss
        @Environment(\.allowAutoDismiss) var allowDismiss

        @ObservedObject var viewModel: ConversationViewModel
        @Binding var message: DataState<BaseMessage>
        let conversationPath: ConversationPath?

        var body: some View {
            if message.value is Message,
               let conversationPath {
                Divider()
                Button(R.string.localizable.replyInThread(), systemImage: "text.bubble") {
                    if let messagePath = MessagePath(
                        message: $message,
                        conversationPath: conversationPath,
                        conversationViewModel: viewModel
                    ) {
                        if allowDismiss {
                            dismiss()
                        }
                        navigationController.path.append(messagePath)
                    } else {
                        viewModel.presentError(userFacingError: UserFacingError(title: R.string.localizable.detailViewCantBeOpened()))
                    }
                }
            }
        }
    }

    struct CopyTextButton: View {
        @Environment(\.allowAutoDismiss) var allowDismiss
        @Environment(\.dismiss) var dismiss
        @Binding var message: DataState<BaseMessage>
        @State private var showSuccess = false

        var body: some View {
            Button(R.string.localizable.copyText(), systemImage: "doc.on.doc") {
                UIPasteboard.general.string = message.value?.content
                if allowDismiss {
                    dismiss()
                } else {
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
        @Environment(\.allowAutoDismiss) var allowDismiss
        @Environment(\.dismiss) var dismiss
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
                        showEditSheet = true
                    }
                    .sheet(isPresented: $showEditSheet) {
                        editMessage
                            .font(nil)
                    }

                    Button(R.string.localizable.deleteMessage(), systemImage: "trash", role: .destructive) {
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
                                if success {
                                    if allowDismiss {
                                        dismiss()
                                    }
                                    // if we deleted a Message and are in the MessageDetailView we pop it
                                    if navigationController.path.count == 3 && tempMessage is Message {
                                        navigationController.path.removeLast()
                                    }
                                }
                            }
                        }
                        Button(R.string.localizable.cancel(), role: .cancel) { }
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
                                configuration: .editMessage(message, { self.dismiss() }),
                                delegate: SendMessageViewModelDelegate(viewModel)
                            )
                        )
                    } else if let answerMessage = message.value as? AnswerMessage {
                        SendMessageView(
                            viewModel: SendMessageViewModel(
                                course: viewModel.course,
                                conversation: viewModel.conversation,
                                configuration: .editAnswerMessage(answerMessage, { self.dismiss() }),
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
            .presentationDetents([.height(200), .medium])
        }
    }
}

struct MessageActionSheet: View {
    @ObservedObject var viewModel: ConversationViewModel
    @Binding var message: DataState<BaseMessage>
    let conversationPath: ConversationPath?
    @State var reactionsViewModel: ReactionsViewModel

    init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>, conversationPath: ConversationPath?) {
        self.viewModel = viewModel
        self._message = message
        self.conversationPath = conversationPath
        self._reactionsViewModel = State(initialValue: ReactionsViewModel(conversationViewModel: viewModel, message: message))
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: .l) {
                HStack(spacing: .m) {
                    EmojiTextButton(viewModel: reactionsViewModel, emoji: "😂")
                    EmojiTextButton(viewModel: reactionsViewModel, emoji: "👍")
                    EmojiTextButton(viewModel: reactionsViewModel, emoji: "➕")
                    EmojiTextButton(viewModel: reactionsViewModel, emoji: "🚀")
                    EmojiPickerButton(viewModel: reactionsViewModel)
                }
                .padding(.l)
                MessageActions.ReplyInThreadButton(viewModel: viewModel, message: $message, conversationPath: conversationPath)
                    .padding(.horizontal)
                Divider()
                MessageActions.CopyTextButton(message: $message)
                    .padding(.horizontal)

                MessageActions.EditDeleteSection(viewModel: viewModel, message: $message)
                    .padding(.horizontal)

                Spacer()
            }
            .buttonStyle(.plain)
            .font(.headline)
            .symbolVariant(.fill)
            .imageScale(.large)
            Spacer()
        }
        .padding(.vertical, .xl)
        .frame(maxHeight: .infinity, alignment: .top)
        .loadingIndicator(isLoading: $viewModel.isLoading)
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
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
            .padding(.m)
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
                .padding(20)
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

// MARK: - Environment+AutoDismiss

private enum SheetAutoDismissEnvironmentKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var allowAutoDismiss: Bool {
        get {
            self[SheetAutoDismissEnvironmentKey.self]
        }
        set {
            self[SheetAutoDismissEnvironmentKey.self] = newValue
        }
    }
}
