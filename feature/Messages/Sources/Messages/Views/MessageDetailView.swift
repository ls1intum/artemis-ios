//
//  MessageDetailView.swift
//  
//
//  Created by Sven Andabaka on 08.04.23.
//

import SwiftUI
import SharedModels
import EmojiPicker
import ArtemisMarkdown
import Smile

struct MessageDetailView: View {

    @ObservedObject var viewModel: ConversationViewModel

    @State private var showEmojiPicker = false
    @State var selectedEmoji: Emoji?

    let message: Message

    let rows = [ GridItem() ]

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

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                HStack(alignment: .top, spacing: .l) {
                    Image(systemName: "person")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .padding(.top, .s)
                    VStack(alignment: .leading, spacing: .m) {
                        Text(message.author?.name ?? "")
                            .bold()
                        if let creationDate = message.creationDate {
                            Text(creationDate, formatter: DateFormatter.timeOnly)
                                .font(.caption)
                        }
                    }
                }

                ArtemisMarkdownView(string: message.content ?? "")

                reactions
            }.padding(.horizontal, .l)
            Divider()
            ScrollView {
                VStack {
                    ForEach(message.answers ?? [], id: \.id) { answerMessage in
                        ThreadMessageCell(message: answerMessage)
                    }
                }.padding(.horizontal, .l)
            }
            Spacer()
            SendMessageView(viewModel: viewModel)
        }.navigationTitle("Thread")
    }

    var reactions: some View {
        LazyHGrid(rows: rows) {
            ForEach(mappedReaction.sorted(by: { $0.key < $1.key }), id: \.key) { map in
                HStack {
                    Text(map.key)
                }
            }
            Button(action: { showEmojiPicker = true }, label: {
                Image("face-smile", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: .smallImage)
                    .padding(.s)
                    .background(Capsule().fill(.gray))
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
}

struct ThreadMessageCell: View {

    var message: AnswerMessage

    var body: some View {
        HStack(alignment: .top, spacing: .l) {
            Image(systemName: "person")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(.top, .s)
            VStack(alignment: .leading, spacing: .m) {
                HStack(alignment: .bottom, spacing: .m) {
                    Text(message.author?.name ?? "")
                        .bold()
                    if let creationDate = message.creationDate {
                        Text(creationDate, formatter: RelativeDateTimeFormatter.formatter)
                            .font(.caption)
                    }
                }
                ArtemisMarkdownView(string: message.content ?? "")
            }
            Spacer()
        }
    }
}
