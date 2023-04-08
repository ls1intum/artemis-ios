//
//  MessageDetailView.swift
//  
//
//  Created by Sven Andabaka on 08.04.23.
//

import SwiftUI
import SharedModels
import ArtemisMarkdown

struct MessageDetailView: View {

    @ObservedObject var viewModel: ConversationViewModel

    let message: Message

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
                Button("Emoji TODO") {
                    print("TODO")
                }
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
