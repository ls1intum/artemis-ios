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

struct MessageActionSheet: View {

    @EnvironmentObject var navigationController: NavigationController
    @Environment(\.dismiss) var dismiss

    let message: BaseMessage
    let conversationPath: ConversationPath?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: .l) {
                HStack(spacing: .m) {
                    EmojiTextButton(emoji: "😂")
                    EmojiTextButton(emoji: "👍")
                    EmojiTextButton(emoji: "➕")
                    EmojiTextButton(emoji: "🚀")
                    EmojiPickerButton(message: message)
                }
                    .padding(.l)
                if let message = message as? Message,
                   let conversationPath {
                    Divider()
                    Button(action: {
                        dismiss()
                        navigationController.path.append(MessagePath(message: message, coursePath: conversationPath.coursePath, conversationPath: conversationPath))
                    }, label: {
                        ButtonContent(title: R.string.localizable.replyInThread(), icon: "text.bubble.fill")
                    })
                }
                Divider()
                Button(action: {
                    UIPasteboard.general.string = message.content
                    dismiss()
                }, label: {
                    ButtonContent(title: R.string.localizable.copyText(), icon: "clipboard.fill")
                })
                Divider()
                Button(action: {
                    print("edit todo")
                }, label: {
                    ButtonContent(title: R.string.localizable.editMessage(), icon: "pencil")
                })
                Button(action: {
                    print("delete todo")
                }, label: {
                    ButtonContent(title: R.string.localizable.deleteMessage(), icon: "trash.fill")
                        .foregroundColor(.red)
                })
                Spacer()
            }
            Spacer()
        }
            .padding(.vertical, .xxl)
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
    }
}

private struct EmojiPickerButton: View {

    @State private var showEmojiPicker = false
    @State var selectedEmoji: Emoji?

    let message: BaseMessage

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
    }
}
