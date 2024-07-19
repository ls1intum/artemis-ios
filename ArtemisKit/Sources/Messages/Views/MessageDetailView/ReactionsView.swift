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
        .popover(isPresented: $viewModel.showAuthorsSheet, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
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
        VStack {
            let mappedReactions = viewModel.mappedReaction(message: message)

            ScrollView(.horizontal, showsIndicators: false) {
                filterRow(mappedReactions: mappedReactions)
            }
            .frame(height: 40, alignment: .top)
            .contentMargins(.leading, .l, for: .scrollContent)
            .contentMargins(.trailing, UIDevice.current.userInterfaceIdiom != .pad ? 90 : .l, for: .scrollContent)
            .overlay(alignment: .trailing) {
                closeButton
            }

            TabView(selection: $viewModel.selectedReactionSheet) {
                ForEach(["All"] + mappedReactions.keys.sorted(), id: \.self) { key in
                    reactionsList(for: key, mappedReactions: mappedReactions)
                        .tag(key)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .padding(.top)
        .presentationDetents([.medium, .large])
        .frame(minWidth: 250, minHeight: 300)
    }

    @ViewBuilder var closeButton: some View {
        if UIDevice.current.userInterfaceIdiom != .pad {
            ZStack(alignment: .trailing) {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .init(
                            uiColor: .systemBackground
                        ), location: 0.4)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 90)
                Button {
                    viewModel.showAuthorsSheet = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .padding(5)
                        .frame(width: 40, height: 40)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, .m)
            }
        }
    }

    @ViewBuilder
    func filterRow(mappedReactions: [String: [Reaction]]) -> some View {
        LazyHStack(alignment: .top) {
            ForEach(["All"] + mappedReactions.keys.sorted(), id: \.self) { key in
                Button {
                    withAnimation {
                        viewModel.selectedReactionSheet = key
                    }
                } label: {
                    let total = mappedReactions.reduce(0) { partialResult, pair in
                        partialResult + pair.1.count
                    }
                    Text(key == "All" ? R.string.localizable.all(total) : key)
                        .containerRelativeFrame(.vertical)
                        .padding(.horizontal, .m)
                        .font(key == "All" ? .body : .title)
                        .background(key == viewModel.selectedReactionSheet ? .gray.opacity(0.5) : .clear, in: .capsule)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    func reactionsList(for key: String, mappedReactions: [String: [Reaction]]) -> some View {
        ScrollView {
            let keys = key == "All" ? mappedReactions.keys.sorted() : [key]
            ForEach(keys, id: \.self) { key in
                if let reactions = mappedReactions[key] {
                    ForEach(reactions, id: \.id) { reaction in
                        if let name = reaction.user?.name {
                            Text("\(key) \(name)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                                .padding([.top, .horizontal])
                        }
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
