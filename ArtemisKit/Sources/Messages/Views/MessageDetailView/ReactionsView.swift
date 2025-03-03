//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 08.04.23.
//

import Common
import SharedModels
import Smile
import SwiftUI
import UserStore

struct ReactionsView: View {
    @Environment(\.isEmojiPickerButtonVisible) var isEmojiPickerButtonVisible: Bool

    @State var viewModel: ReactionsViewModel
    @Binding var message: DataState<BaseMessage>

    let columns = [ GridItem(.adaptive(minimum: 50)) ]

    init(
        viewModel: ConversationViewModel,
        message: Binding<DataState<BaseMessage>>
    ) {
        self._viewModel = State(initialValue: ReactionsViewModel(conversationViewModel: viewModel, message: message))
        self._message = message
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading) {
            ForEach(viewModel.mappedReaction.sorted(by: { $0.key < $1.key }), id: \.key) { map in
                EmojiTextButton(viewModel: viewModel, pair: (map.key, map.value))
            }
            if !viewModel.mappedReaction.isEmpty || isEmojiPickerButtonVisible {
                EmojiPickerButton(viewModel: viewModel)
            }
        }
        .popover(isPresented: $viewModel.showAuthorsSheet, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            ReactionAuthorsSheet(viewModel: viewModel)
        }
        .onChange(of: message, { _, newValue in
            viewModel.message = newValue
        })
    }
}

private struct EmojiTextButton: View {

    var viewModel: ReactionsViewModel

    let pair: (String, [Reaction])

    var body: some View {
        Button {
        } label: {
            Text("\(pair.0) \(pair.1.count)")
                .font(.footnote)
                .foregroundColor(viewModel.isMyReaction(pair.0) ? Color.Artemis.artemisBlue : Color.Artemis.primaryLabel)
                .frame(height: .extraSmallImage)
                .padding(.m)
                .background(
                    Group {
                        if viewModel.isMyReaction(pair.0) {
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

struct ReactionAuthorsSheet: View {
    @Bindable var viewModel: ReactionsViewModel

    var body: some View {
        VStack {
            let mappedReactions = viewModel.mappedReaction

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    filterRow(mappedReactions: mappedReactions)
                }
                .frame(height: 40, alignment: .top)
                .contentMargins(.leading, .l, for: .scrollContent)
                .contentMargins(.trailing, 90, for: .scrollContent)
                .onChange(of: viewModel.selectedReactionSheet, initial: true) { _, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue)
                    }
                }
            }
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
            .allowsHitTesting(false)

            Button {
                viewModel.showAuthorsSheet = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .padding(5)
                    .frame(width: 40, height: 40)
            }
            .foregroundStyle(.secondary)
            .padding(.trailing, .m)
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
            NavigationStack {
                EmojiPicker(viewModel: viewModel)
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
