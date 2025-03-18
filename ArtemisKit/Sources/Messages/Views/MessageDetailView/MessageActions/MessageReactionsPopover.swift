//
//  MessageReactionsPopover.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.03.25.
//

import Common
import Navigation
import SharedModels
import Smile
import SwiftUI

struct MessageReactionsPopover: View {
    @ObservedObject var viewModel: ConversationViewModel
    @State var reactionsViewModel: ReactionsViewModel

    init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>, conversationPath: ConversationPath?) {
        self.viewModel = viewModel
        self._reactionsViewModel = State(initialValue: ReactionsViewModel(conversationViewModel: viewModel, message: message))
    }

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: .m) {
                EmojiTextButton(viewModel: reactionsViewModel, emoji: "😂")
                EmojiTextButton(viewModel: reactionsViewModel, emoji: "👍")
                EmojiTextButton(viewModel: reactionsViewModel, emoji: "➕")
                EmojiTextButton(viewModel: reactionsViewModel, emoji: "🚀")
                EmojiPickerButton(viewModel: reactionsViewModel)
            }
            .padding(.m)
            .buttonStyle(.plain)
            .font(.headline)
            .symbolVariant(.fill)
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
            .background(.bar, in: .rect(cornerRadius: 10))

            Button {
                viewModel.selectedMessageId = nil
            } label: {
                Image(systemName: "xmark.circle")
            }
            .font(.title2)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct EmojiTextButton: View {

    var viewModel: ReactionsViewModel

    let emoji: String

    var body: some View {
        Text("\(emoji)")
            .font(.title3)
            .foregroundColor(Color.Artemis.primaryLabel)
            .frame(width: .mediumImage * 0.75, height: .mediumImage * 0.75)
            .padding(.s)
            .background(
                Capsule().fill(Color.Artemis.reactionCapsuleColor)
            )
            .onTapGesture {
                if let emojiId = Smile.alias(emoji: emoji) {
                    Task {
                        await viewModel.addReaction(emojiId: emojiId)
                    }
                }
            }
    }
}

private struct EmojiPickerButton: View {

    var viewModel: ReactionsViewModel

    @State private var showEmojiPicker = false

    var body: some View {
        Button {
            showEmojiPicker = true
        } label: {
            Image("face-smile", bundle: .module)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.Artemis.secondaryLabel)
                .frame(width: .smallImage * 0.75, height: .smallImage * 0.75)
                .padding(.m * 1.5)
                .background(Capsule().fill(Color.Artemis.reactionCapsuleColor))
        }
        .sheet(isPresented: $showEmojiPicker) {
            NavigationStack {
                EmojiPicker(viewModel: viewModel)
            }
        }
    }
}
