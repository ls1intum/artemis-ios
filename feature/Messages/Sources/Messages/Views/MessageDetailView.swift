//
//  MessageDetailView.swift
//  
//
//  Created by Sven Andabaka on 08.04.23.
//

import SwiftUI
import SharedModels
import ArtemisMarkdown
import Navigation

struct MessageDetailView: View {

    @ObservedObject var viewModel: ConversationViewModel

    @State private var showMessageActionSheet = false

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

                ReactionsView(message: message)
            }
                .padding(.horizontal, .l)
                .contentShape(Rectangle())
                .onLongPressGesture(maximumDistance: 30) {
                    let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                    impactMed.impactOccurred()
                    showMessageActionSheet = true
                }
                .sheet(isPresented: $showMessageActionSheet) {
                    MessageActionSheet(message: message, conversationPath: nil)
                        .presentationDetents([.height(250), .large])
                }
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
