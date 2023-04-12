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
import DesignLibrary
import Common

public struct MessageDetailView: View {

    @ObservedObject var viewModel: ConversationViewModel

    @State private var showMessageActionSheet = false

    @State private var message: DataState<Message>

    private let messageId: Int64

    public init(viewModel: ConversationViewModel,
                message: Message) {
        self.viewModel = viewModel
        self.messageId = message.id
        self._message = State(wrappedValue: .done(response: message))
    }

    public init(viewModel: ConversationViewModel,
                messageId: Int64) {
        self.viewModel = viewModel
        self.messageId = messageId
        self._message = State(wrappedValue: .loading)
    }

    public var body: some View {
        DataStateView(data: $message, retryHandler: { await loadMessage() }) { message in
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
                        .presentationDetents([.height(350), .large])
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
            }.navigationTitle(R.string.localizable.thread())
        }
            .task {
                await loadMessage()
            }
    }

    private func loadMessage() async {
        if message.value == nil {
            let result = await MessagesServiceFactory.shared.getMessages(for: viewModel.courseId, and: viewModel.conversationId, size: 50)

            switch result {
            case .loading:
                message = .loading
            case .failure(let error):
                message = .failure(error: error)
            case .done(let response):
                guard let message = response.first(where: { $0.id == messageId }) else {
                    message = .failure(error: UserFacingError(title: R.string.localizable.messageCouldNotBeLoadedError()))
                    return
                }
                self.message = .done(response: message)
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
