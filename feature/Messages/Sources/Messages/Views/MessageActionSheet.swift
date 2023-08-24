//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 08.04.23.
//

import SwiftUI
import SharedModels
import UserStore
import EmojiPicker
import Navigation
import Common
import Smile

struct MessageActionSheet: View {

    @EnvironmentObject var navigationController: NavigationController
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: ConversationViewModel

    @Binding var message: DataState<BaseMessage>
    let conversationPath: ConversationPath?

    @State private var showDeleteAlert = false
    @State private var showEditSheet = false

    var isAbleToEditDelete: Bool {
        guard let message = message.value else { return false }

        if message.isCurrentUserAuthor {
            return true
        }

        guard let channel = viewModel.conversation.value?.baseConversation as? Channel else { return false }
        if channel.hasChannelModerationRights ?? false && message is Message {
            return true
        }

        return false
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: .l) {
                HStack(spacing: .m) {
                    EmojiTextButton(viewModel: viewModel, message: $message, emoji: "😂")
                    EmojiTextButton(viewModel: viewModel, message: $message, emoji: "👍")
                    EmojiTextButton(viewModel: viewModel, message: $message, emoji: "➕")
                    EmojiTextButton(viewModel: viewModel, message: $message, emoji: "🚀")
                    EmojiPickerButton(viewModel: viewModel, message: $message)
                }
                    .padding(.l)
                if message.value is Message,
                   let conversationPath {
                    Divider()
                    Button(action: {
                        if let messagePath = MessagePath(message: $message, coursePath: conversationPath.coursePath, conversationPath: conversationPath, conversationViewModel: viewModel) {
                            dismiss()
                            navigationController.path.append(messagePath)
                        } else {
                            viewModel.presentError(userFacingError: UserFacingError(title: R.string.localizable.detailViewCantBeOpened()))
                        }
                    }, label: {
                        ButtonContent(title: R.string.localizable.replyInThread(), icon: "text.bubble.fill")
                    })
                }
                Divider()
                Button(action: {
                    UIPasteboard.general.string = message.value?.content
                    dismiss()
                }, label: {
                    ButtonContent(title: R.string.localizable.copyText(), icon: "clipboard.fill")
                })
                Divider()
                Button {
                    //
                } label: {
                    ButtonContent(title: "Report Post", icon: "exclamationmark.bubble.fill")
                        .foregroundColor(.red)
                }


                editDeleteSection

                Spacer()
            }
            Spacer()
        }
            .padding(.vertical, .xxl)
            .loadingIndicator(isLoading: $viewModel.isLoading)
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }

    var editDeleteSection: some View {
        Group {
            if isAbleToEditDelete {
                Divider()

                Button(action: {
                    showEditSheet = true
                }, label: {
                    ButtonContent(title: R.string.localizable.editMessage(), icon: "pencil")
                })
                    .sheet(isPresented: $showEditSheet) {
                        NavigationView {
                            Group {
                                if let message = message.value as? Message {
                                    SendMessageView(viewModel: viewModel, sendMessageType: .editMessage(message, { self.dismiss() }))
                                } else if let answerMessage = message.value as? AnswerMessage {
                                    SendMessageView(viewModel: viewModel, sendMessageType: .editAnswerMessage(answerMessage, { self.dismiss() }))
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
                        }.presentationDetents([.height(200), .medium])
                    }

                Button(action: {
                    showDeleteAlert = true
                }, label: {
                    ButtonContent(title: R.string.localizable.deleteMessage(), icon: "trash.fill")
                        .foregroundColor(.red)
                })
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
                                    dismiss()
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
}

private struct ButtonContent: View {

    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: .s) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: .mediumImage, height: .smallImage)
            Text(title)
                .font(.headline)
        }
            .padding(.horizontal, .l)
            .foregroundColor(.Artemis.primaryLabel)
    }
}

private struct EmojiTextButton: View {

    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: ConversationViewModel

    @Binding var message: DataState<BaseMessage>

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
                        if let message = message.value as? Message {
                            let result = await viewModel.addReactionToMessage(for: message, emojiId: emojiId)
                            switch result {
                            case .loading:
                                self.message = .loading
                            case .failure(let error):
                                self.message = .failure(error: error)
                            case .done(let response):
                                self.message = .done(response: response)
                            }
                        } else if let answerMessage = message.value as? AnswerMessage {
                            let result = await viewModel.addReactionToAnswerMessage(for: answerMessage, emojiId: emojiId)
                            switch result {
                            case .loading:
                                self.message = .loading
                            case .failure(let error):
                                self.message = .failure(error: error)
                            case .done(let response):
                                self.message = .done(response: response)
                            }
                        }
                        dismiss()
                    }
                }
            }
    }
}

private struct EmojiPickerButton: View {

    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: ConversationViewModel

    @Binding var message: DataState<BaseMessage>

    @State private var showEmojiPicker = false
    @State var selectedEmoji: Emoji?

    var body: some View {
        Button(action: { showEmojiPicker = true }, label: {
            Image("face-smile", bundle: .module)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.Artemis.secondaryLabel)
                .frame(width: .smallImage, height: .smallImage)
                .padding(20)
                .background(Capsule().fill(Color.Artemis.reactionCapsuleColor))
        })
            .sheet(isPresented: $showEmojiPicker) {
                NavigationView {
                    EmojiPickerView(selectedEmoji: $selectedEmoji, selectedColor: Color.Artemis.artemisBlue)
                        .navigationTitle(R.string.localizable.emojis())
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .onChange(of: selectedEmoji) { newEmoji in
                if let newEmoji,
                   let emojiId = Smile.alias(emoji: newEmoji.value) {
                    Task {
                        if let message = message.value as? Message {
                            let result = await viewModel.addReactionToMessage(for: message, emojiId: emojiId)
                            switch result {
                            case .loading:
                                self.message = .loading
                            case .failure(let error):
                                self.message = .failure(error: error)
                            case .done(let response):
                                self.message = .done(response: response)
                            }
                        } else if let answerMessage = message.value as? AnswerMessage {
                            let result = await viewModel.addReactionToAnswerMessage(for: answerMessage, emojiId: emojiId)
                            switch result {
                            case .loading:
                                self.message = .loading
                            case .failure(let error):
                                self.message = .failure(error: error)
                            case .done(let response):
                                self.message = .done(response: response)
                            }
                        }
                        selectedEmoji = nil
                        dismiss()
                    }
                }
            }
    }
}

struct MessageActionSheet_Previews: PreviewProvider {
    static var previews: some View {
//        MessageActionSheet(
//            viewModel: .init(
//                course: .init(
//                    id: 1,
//                    courseInformationSharingConfiguration: .communicationAndMessaging),
//                conversation: .unknown(
//                    conversation: .init(from: <#T##Decoder#>))),
//            message: .constant(.loading),
//            conversationPath: ConversationPath?.none)
        Text("Hello, world!")
    }
}
