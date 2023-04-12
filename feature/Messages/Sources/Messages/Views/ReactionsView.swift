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

    @ObservedObject private var viewModel: ConversationViewModel

    let message: BaseMessage
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

    init(viewModel: ConversationViewModel, message: BaseMessage, showEmojiAddButton: Bool = true) {
        self.viewModel = viewModel
        self.message = message
        self.showEmojiAddButton = showEmojiAddButton
    }

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(mappedReaction.sorted(by: { $0.key < $1.key }), id: \.key) { map in
                EmojiTextButton(viewModel: viewModel, pair: (map.key, map.value), message: message)
            }
            if !mappedReaction.isEmpty || showEmojiAddButton {
                EmojiPickerButton(viewModel: viewModel, message: message)
            }
        }
    }
}

private struct EmojiTextButton: View {

    @ObservedObject var viewModel: ConversationViewModel

    let pair: (String, [Reaction])
    let message: BaseMessage

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
            .onTapGesture {
                if let emojiId = Smile.alias(emoji: pair.0) {
                    Task {
                        if let message = message as? Message {
                            _ = await viewModel.addReactionToMessage(for: message, emojiId: emojiId)
                        } else {
                            // TODO
                        }
                    }
                }
            }
    }

    private var isMyReaction: Bool {
        if let emojiId = Smile.alias(emoji: pair.0) {
            return message.containsReactionFromMe(emojiId: emojiId)
        }
        return false
    }
}

private struct EmojiPickerButton: View {

    @ObservedObject var viewModel: ConversationViewModel

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
            .onChange(of: selectedEmoji) { newEmoji in
                if let newEmoji,
                   let emojiId = Smile.alias(emoji: newEmoji.value) {
                    Task {
                        if let message = message as? Message {
                            let result = await viewModel.addReactionToMessage(for: message, emojiId: emojiId)
                            switch result {
                            default:
                                selectedEmoji = nil
                            }
                        } else {
                            // TODO
                        }
                    }
                }
            }
    }
}
