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
import Common

struct ReactionsView: View {

    @ObservedObject private var viewModel: ConversationViewModel

    @Binding var message: DataState<BaseMessage>
    let showEmojiAddButton: Bool

    @State private var viewRerenderWorkaround = false
    let columns = [ GridItem(.adaptive(minimum: 45)) ]

    var mappedReaction: [String: [Reaction]] {
        var reactions = [String: [Reaction]]()

        message.value?.reactions?.forEach {
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

    init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>, showEmojiAddButton: Bool = true) {
        self.viewModel = viewModel
        self._message = message
        self.showEmojiAddButton = showEmojiAddButton
    }

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(mappedReaction.sorted(by: { $0.key < $1.key }), id: \.key) { map in
                EmojiTextButton(viewModel: viewModel, pair: (map.key, map.value), message: $message)
            }
            if !mappedReaction.isEmpty || showEmojiAddButton {
                EmojiPickerButton(viewModel: viewModel, message: $message, viewRerenderWorkaround: $viewRerenderWorkaround)
            }
        }
    }
}

private struct EmojiTextButton: View {

    @ObservedObject var viewModel: ConversationViewModel

    let pair: (String, [Reaction])
    @Binding var message: DataState<BaseMessage>

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
                    }
                }
            }
    }

    private var isMyReaction: Bool {
        if let emojiId = Smile.alias(emoji: pair.0),
           let message = message.value {
            return message.containsReactionFromMe(emojiId: emojiId)
        }
        return false
    }
}

private struct EmojiPickerButton: View {

    @ObservedObject var viewModel: ConversationViewModel

    @State private var showEmojiPicker = false
    @State var selectedEmoji: Emoji?

    @Binding var message: DataState<BaseMessage>
    @Binding var viewRerenderWorkaround: Bool

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
                        viewRerenderWorkaround.toggle()
                        selectedEmoji = nil
                    }
                }
            }
    }
}
