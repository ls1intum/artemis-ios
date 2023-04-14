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
    @Binding private var message: DataState<BaseMessage>

    @State private var showMessageActionSheet = false

    private let messageId: Int64?

    public init(viewModel: ConversationViewModel,
                message: Binding<DataState<BaseMessage>>) {
        self.viewModel = viewModel
        self.messageId = message.wrappedValue.value?.id
        self._message = message
    }

    public init(viewModel: ConversationViewModel,
                messageId: Int64) {
        self.viewModel = viewModel
        self.messageId = messageId
        // TODO: check what to do here
        self._message = Binding(get: { .loading }, set: { print($0) })
    }

    public var body: some View {
        DataStateView(data: $message, retryHandler: { await reloadMessage() }) { message in
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

                    ReactionsView(viewModel: viewModel, message: $message, reloadCompletion: { })
                }
                .padding(.horizontal, .l)
                .contentShape(Rectangle())
                .onLongPressGesture(maximumDistance: 30) {
                    let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                    impactMed.impactOccurred()
                    showMessageActionSheet = true
                }
                .sheet(isPresented: $showMessageActionSheet) {
                    MessageActionSheet(viewModel: viewModel, message: $message, conversationPath: nil)
                        .presentationDetents([.height(350), .large])
                }
                if let message = message as? Message {
                    Divider()
                    ScrollView {
                        VStack {
                            ForEach(Array((message.answers ?? []).enumerated()), id: \.1) { index, answerMessage in
                                MessageCellWrapper(viewModel: viewModel,
                                                   answerMessage: answerMessage,
                                                   showHeader: (index == 0 ? true : shouldShowHeader(message: answerMessage, previousMessage: message.answers![index - 1])))
                            }
                        }.padding(.horizontal, .l)
                    }
                }
                Spacer()
                if !((viewModel.conversation.value?.baseConversation as? Channel)?.isArchived ?? false),
                   let message = message as? Message {
                    SendMessageView(viewModel: viewModel, sendMessageType: .answerMessage(message, { await reloadMessage() }))
                }
            }.navigationTitle(R.string.localizable.thread())
        }
            .task {
                if message.value == nil {
                    await reloadMessage()
                }
            }
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }

    // TODO: Create MessageDetailViewModel and extract logic there -> also move message there and make it available from all subviews -> replace reloadCompletion with it
    private func reloadMessage() async {
        guard let messageId else { return }
        let result = await viewModel.loadMessage(messageId: messageId)
        switch result {
        case .loading:
            message = .loading
        case .failure(let error):
            message = .failure(error: error)
        case .done(let response):
            message = .done(response: response)
        }
    }

    // header is not shown if same person messages multiple times within 5 minutes
    private func shouldShowHeader(message: AnswerMessage, previousMessage: AnswerMessage) -> Bool {
        !(message.author == previousMessage.author &&
          message.creationDate ?? .now < (previousMessage.creationDate ?? .yesterday).addingTimeInterval(TimeInterval(MAX_MINUTES_FOR_GROUPING_MESSAGES * 60)))
    }
}

private struct MessageCellWrapper: View {

    @ObservedObject var viewModel: ConversationViewModel

    let answerMessage: AnswerMessage
    let showHeader: Bool

    private var answerMessageBinding: Binding<DataState<BaseMessage>> {
        Binding(get: {
            if let day = answerMessage.creationDate?.startOfDay,
               let messageIndex = viewModel.dailyMessages.value?[day]?.firstIndex(where: { $0.answers?.contains(where: { $0.id == answerMessage.id }) ?? false }),
               let answerMessage = viewModel.dailyMessages.value?[day]?[messageIndex].answers?.first(where: { $0.id == answerMessage.id }) {
                return .done(response: answerMessage)
            }
            return .loading
        }, set: {
            if  let day = answerMessage.creationDate?.startOfDay,
                let messageIndex = viewModel.dailyMessages.value?[day]?.firstIndex(where: { $0.answers?.contains(where: { $0.id == answerMessage.id }) ?? false }),
                let answerMessageIndex = viewModel.dailyMessages.value?[day]?[messageIndex].answers?.firstIndex(where: { $0.id == answerMessage.id }),
                let newAnswerMessage = $0.value as? AnswerMessage {

                viewModel.dailyMessages.value?[day]?[messageIndex].answers?[answerMessageIndex] = newAnswerMessage
            }
        })
    }

    var body: some View {
        MessageCell(viewModel: viewModel,
                    message: answerMessageBinding,
                    conversationPath: nil,
                    showHeader: showHeader,
                    reloadCompletion: { })
    }
}
