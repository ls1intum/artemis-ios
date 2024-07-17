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
    @Environment(\.isEmojiPickerButtonVisible) var isEmojiPickerButtonVisible: Bool

    @State var viewModel: ReactionsViewModel
    @Binding var message: DataState<BaseMessage>

    @State private var viewRerenderWorkaround = false

    let columns = [ GridItem(.adaptive(minimum: 45)) ]

    init(
        viewModel: ConversationViewModel,
        message: Binding<DataState<BaseMessage>>
    ) {
        self._viewModel = State(initialValue: ReactionsViewModel(conversationViewModel: viewModel, message: message))
        self._message = message
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading) {
            ForEach(viewModel.mappedReaction(message: message).sorted(by: { $0.key < $1.key }), id: \.key) { map in
                EmojiTextButton(viewModel: viewModel, message: $message, pair: (map.key, map.value))
            }
            if !viewModel.mappedReaction(message: message).isEmpty || isEmojiPickerButtonVisible {
                EmojiPickerButton(viewModel: viewModel, viewRerenderWorkaround: $viewRerenderWorkaround)
            }
        }
        .sheet(isPresented: $viewModel.showAuthorsSheet) {
            ReactionAuthorsSheet(viewModel: viewModel, message: $message)
        }
    }
}

private struct EmojiTextButton: View {

    var viewModel: ReactionsViewModel
    @Binding var message: DataState<BaseMessage>

    let pair: (String, [Reaction])

    var body: some View {
        Button {
        } label: {
            Text("\(pair.0) \(pair.1.count)")
                .font(.footnote)
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
        .simultaneousGesture(TapGesture()
            .onEnded { _ in
                if let emojiId = Smile.alias(emoji: pair.0) {
                    Task {
                        await viewModel.addReaction(emojiId: emojiId)
                    }
                }
            }
        )
        .simultaneousGesture(LongPressGesture()
            .onEnded { _ in
                viewModel.selectedReactionSheet = pair.0
                viewModel.showAuthorsSheet = true
            }
        )
    }
}

private extension EmojiTextButton {
    var isMyReaction: Bool {
        guard let emojiId = Smile.alias(emoji: pair.0),
              let message = message.value else {
            return false
        }

        return message.containsReactionFromMe(emojiId: emojiId)
    }
}

struct ReactionAuthorsSheet: View {
    @Bindable var viewModel: ReactionsViewModel
    @Binding var message: DataState<BaseMessage>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                let mappedReactions = viewModel.mappedReaction(message: message)

                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(mappedReactions.keys.sorted(), id: \.self) { key in
                            Button {
                                withAnimation {
                                    viewModel.selectedReactionSheet = key
                                }
                            } label: {
                                Text(key)
                                    .padding(.horizontal, .m)
                                    .font(.title)
                                    .background(key == viewModel.selectedReactionSheet ? .gray : .clear, in: .capsule)
                            }
                        }
                    }
                }
                .frame(height: .mediumImage, alignment: .top)
                .contentMargins(.horizontal, .l, for: .scrollContent)

                TabView(selection: $viewModel.selectedReactionSheet) {
                    ForEach(mappedReactions.keys.sorted(), id: \.self) { key in
                        ScrollView {
                            if let reactions = mappedReactions[key] {
                                ForEach(reactions, id: \.id) { reaction in
                                    if let name = reaction.user?.name {
                                        Text("\(key) \(name)")
                                    }
                                }
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding([.top, .horizontal])
                            }
                        }
                        .tag(key)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(R.string.localizable.close()) {
                        viewModel.showAuthorsSheet = false
                        viewModel.selectedReactionSheet = ""
                    }
                }
            }
        }
    }
}

private struct EmojiPickerButton: View {

    var viewModel: ReactionsViewModel

    @State private var isEmojiPickerPresented = false
    @State var selectedEmoji: Emoji?

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
                    await viewModel.addReaction(emojiId: emojiId)
                    viewRerenderWorkaround.toggle()
                    selectedEmoji = nil
                }
            }
        }
    }
}

// MARK: - Environment+IsEmojiPickerVisible

private enum IsEmojiPickerVisibleEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isEmojiPickerButtonVisible: Bool {
        get {
            self[IsEmojiPickerVisibleEnvironmentKey.self]
        }
        set {
            self[IsEmojiPickerVisibleEnvironmentKey.self] = newValue
        }
    }
}

#Preview {
    ReactionsView(
        viewModel: ConversationViewModel(
            course: MessagesServiceStub.course,
            conversation: MessagesServiceStub.conversation),
        message: Binding.constant(DataState<BaseMessage>.done(response: MessagesServiceStub.message))
    )
}
