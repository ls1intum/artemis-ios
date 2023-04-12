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

// swiftlint:disable:next identifier_name
private let MAX_MINUTES_FOR_GROUPING_MESSAGES = 5

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
                            .frame(width: 30, height: 30)
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

                    ReactionsView(viewModel: viewModel, message: message)
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
                        ForEach(Array((message.answers ?? []).enumerated()), id: \.1.id) { index, answerMessage in
                            MessageCell(viewModel: viewModel,
                                        message: answerMessage,
                                        conversationPath: nil,
                                        showHeader: (index == 0 ? true : shouldShowHeader(message: answerMessage, previousMessage: message.answers![index - 1])))
                        }
                    }.padding(.horizontal, .l)
                }
                Spacer()
                SendMessageView(viewModel: viewModel, sendMessageType: .answerMessage(message, { await loadMessage(force: true) }))
            }.navigationTitle(R.string.localizable.thread())
        }
            .task {
                await loadMessage()
            }
    }

    // header is not shown if same person messages multiple times within 5 minutes
    private func shouldShowHeader(message: AnswerMessage, previousMessage: AnswerMessage) -> Bool {
        !(message.author == previousMessage.author &&
          message.creationDate ?? .now < (previousMessage.creationDate ?? .yesterday).addingTimeInterval(TimeInterval(MAX_MINUTES_FOR_GROUPING_MESSAGES * 60)))
    }

    private func loadMessage(force: Bool = false) async {
        if message.value == nil || force {
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
