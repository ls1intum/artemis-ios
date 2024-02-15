//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 08.04.23.
//

import Common
import EmojiPicker
import SharedModels
import Smile
import SwiftUI
import UserStore

struct ReactionsView: View {

    @ObservedObject private var viewModel: ConversationViewModel

    @Binding var message: DataState<BaseMessage>
    let isEmojiPickerButtonVisible: Bool

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

    init(
        viewModel: ConversationViewModel,
        message: Binding<DataState<BaseMessage>>,
        isEmojiPickerButtonVisible: Bool = true
    ) {
        self.viewModel = viewModel
        self._message = message
        self.isEmojiPickerButtonVisible = isEmojiPickerButtonVisible
    }

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(mappedReaction.sorted(by: { $0.key < $1.key }), id: \.key) { map in
                EmojiTextButton(viewModel: viewModel, pair: (map.key, map.value), message: $message)
            }
            if !mappedReaction.isEmpty || isEmojiPickerButtonVisible {
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
        Button {
            if let emojiId = Smile.alias(emoji: pair.0) {
                Task {
                    await addReaction(emojiId: emojiId)
                }
            }
        } label: {
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
                            Capsule()
                                .fill(Color.Artemis.reactionCapsuleColor)
                        }
                    }
                )
        }
    }
}

private extension EmojiTextButton {
    func addReaction(emojiId: String) async {
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

    var isMyReaction: Bool {
        guard let emojiId = Smile.alias(emoji: pair.0),
           let message = message.value else {
            return false
        }

        return message.containsReactionFromMe(emojiId: emojiId)
    }
}

private struct EmojiPickerButton: View {

    @ObservedObject var viewModel: ConversationViewModel

    @State private var isEmojiPickerPresented = false
    @State var selectedEmoji: Emoji?

    @Binding var message: DataState<BaseMessage>
    @Binding var viewRerenderWorkaround: Bool

    var body: some View {
        Button {
            isEmojiPickerPresented = true
        } label: {
            Image("face-smile", bundle: .module)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.Artemis.secondaryLabel)
                .frame(height: .extraSmallImage)
                .padding(.m)
                .background(Capsule().fill(Color.Artemis.reactionCapsuleColor))
        }
        .sheet(isPresented: $isEmojiPickerPresented) {
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
                    await addReaction(emojiId: emojiId)
                    viewRerenderWorkaround.toggle()
                    selectedEmoji = nil
                }
            }
        }
    }
}

private extension EmojiPickerButton {
    func addReaction(emojiId: String) async {
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

#Preview {
    ReactionsView(
        viewModel: ConversationViewModel(
            course: MessagesServiceStub.course,
            conversation: MessagesServiceStub.conversation),
        message: Binding.constant(DataState<BaseMessage>.done(
            response: MessagesServiceStub.message
        )),
        isEmojiPickerButtonVisible: true)
}
