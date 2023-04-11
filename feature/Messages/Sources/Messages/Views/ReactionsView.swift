//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 08.04.23.
//

import SwiftUI
import SharedModels
import Smile
import UserStore
import EmojiPicker

struct ReactionsView: View {

    let message: Message
    let showEmojiAddButton: Bool

    let columns = [ GridItem(.adaptive(minimum: 45)) ]

    var mappedReaction: [String: [Reaction]] {
        var reactions = [String: [Reaction]]()

        message.reactions?.forEach {
            guard let emoji = Smile.emoji(alias: $0.emojiId) else {
                return
            }
            if reactions[emoji] != nil {
                reactions[emoji]?.append($0)
            } else {
                reactions[emoji] = [$0]
            }
        }
        return reactions
    }

    init(message: Message, showEmojiAddButton: Bool = true) {
        self.message = message
        self.showEmojiAddButton = showEmojiAddButton
    }

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(mappedReaction.sorted(by: { $0.key < $1.key }), id: \.key) { map in
                EmojiTextButton(pair: (map.key, map.value))
            }
            if !mappedReaction.isEmpty || showEmojiAddButton {
                EmojiPickerButton(message: message)
            }
        }
    }
}

private struct EmojiTextButton: View {

    let pair: (String, [Reaction])

    var body: some View {
        Text("\(pair.0) \(pair.1.count)")
            .font(.caption)
            .foregroundColor(isMyReaction ? Color.Artemis.artemisBlue : Color.Artemis.primaryLabel)
            .frame(height: .extraSmallImage)
            .padding(.m)
            .background(
                Group {
                    if isMyReaction {
                        Capsule()
                            .strokeBorder(Color.Artemis.artemisBlue, lineWidth: 1)
                            .background(Capsule().foregroundColor(Color.Artemis.artemisBlue.opacity(0.25)))
                    } else {
                        Capsule().fill(Color.Artemis.reactionCapsuleColor)
                    }
                }
            )
    }

    private var isMyReaction: Bool {
        guard let userId = UserSession.shared.userId else { return false }
        return pair.1.contains(where: {
            guard let authorId = $0.user?.id else { return false }
            return authorId == userId
        })
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
                .frame(height: .extraSmallImage)
                .padding(.m)
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
