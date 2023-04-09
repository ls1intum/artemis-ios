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
            VStack(alignment: .leading, spacing: .m) {
                HStack(spacing: .m) {
                    EmojiTextButton(emoji: "😂")
                    EmojiTextButton(emoji: "👍")
                    EmojiTextButton(emoji: "➕")
                    EmojiTextButton(emoji: "🚀")
                    EmojiPickerButton(message: message)
                }.padding(.horizontal, .l)
                if let conversationPath {
                    Divider()
                    Button(action: {
                        dismiss()
                        navigationController.path.append(MessagePath(message: message, conversationPath: conversationPath))
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
                })
                Spacer()
            }
            Spacer()
        }
            .padding(.vertical, .xl)
    }
}

private struct ButtonContent: View {

    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: .m) {
            Image(systemName: icon)
                .imageScale(.large)
            Text(title)
                .font(.headline)
        }.padding(.horizontal, .l)
    }
}

private struct EmojiTextButton: View {

    let emoji: String

    var body: some View {
        Text("\(emoji)")
            .foregroundColor(Color.Artemis.primaryLabel)
            .frame(height: .smallImage)
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
                .frame(height: .smallImage)
                .padding(.m)
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
