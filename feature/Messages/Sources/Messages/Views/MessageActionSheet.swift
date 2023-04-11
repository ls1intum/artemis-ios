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

    let message: Message
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
                if let conversationPath {
                    Divider()
                    Button(action: {
                        dismiss()
                        navigationController.path.append(MessagePath(message: message, coursePath: conversationPath.coursePath, conversationPath: conversationPath))
                    }, label: {
                        ButtonContent(title: "Reply in Thread", icon: "text.bubble.fill")
                    })
                }
                Divider()
                Button(action: {
                    UIPasteboard.general.string = message.content
                    dismiss()
                }, label: {
                    ButtonContent(title: "Copy Text", icon: "clipboard.fill")
                })
                Divider()
                Button(action: {
                    print("edit todo")
                }, label: {
                    ButtonContent(title: "Edit Message", icon: "pencil")
                })
                Button(action: {
                    print("delete todo")
                }, label: {
                    ButtonContent(title: "Delete Message", icon: "trash.fill")
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

    let message: Message

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
                        .navigationTitle("Emojis")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
    }
}
