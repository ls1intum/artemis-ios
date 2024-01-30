//
//  MessageDetailView.swift
//  
//
//  Created by Sven Andabaka on 08.04.23.
//

import ArtemisMarkdown
import Common
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

// swiftlint:disable:next identifier_name
private let MAX_MINUTES_FOR_GROUPING_MESSAGES = 5

public struct MessageDetailView: View {

    @ObservedObject var viewModel: ConversationViewModel
    @Binding private var message: DataState<BaseMessage>

    @State private var isMessageActionSheetPresented = false
    @State private var viewRerenderWorkaround = false

    private let messageId: Int64?

    @State private var internalMessage: BaseMessage?

    public init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>) {
        self.viewModel = viewModel
        self.messageId = message.wrappedValue.value?.id
        self._message = message
    }

    public init(viewModel: ConversationViewModel, messageId: Int64) {
        self.viewModel = viewModel
        self.messageId = messageId
        self._message = Binding(get: { .loading }, set: { _ in return })
        self.internalMessage = nil

        self._message = Binding(get: { [self] in
            if let internalMessage = self.internalMessage {
                return .done(response: internalMessage)
            }
            return .loading
        }, set: { [self] in
            if let message = $0.value as? Message {
                self.internalMessage = message
            }
        })
    }

    public var body: some View {
        DataStateView(data: $message) {
            await reloadMessage()
        } content: { message in
            VStack(alignment: .leading) {
                ScrollViewReader { proxy in
                    ScrollView {
                        top(message: message)
                        bottom(message: message, proxy: proxy)
                    }
                }
                Spacer()
                if !((viewModel.conversation.value?.baseConversation as? Channel)?.isArchived ?? false),
                   let message = message as? Message {
                    SendMessageView(viewModel: viewModel, sendMessageType: .answerMessage(message, { await reloadMessage() }))
                }
            }
        }
        .navigationTitle(R.string.localizable.thread())
        .task {
            if message.value == nil {
                await reloadMessage()
            }
        }
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }
}

private extension MessageDetailView {
    func top(message: BaseMessage) -> some View {
        VStack(alignment: .leading) {
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
                Spacer()
            }

            ArtemisMarkdownView(string: message.content ?? "")

            if let updatedDate = message.updatedDate {
                Text("\(R.string.localizable.edited()) (\(updatedDate.shortDateAndTime))")
                    .foregroundColor(.Artemis.secondaryLabel)
                    .font(.footnote)
            }

            ReactionsView(viewModel: viewModel, message: $message)
        }
        .padding(.horizontal, .l)
        .contentShape(Rectangle())
        .onLongPressGesture(maximumDistance: 30) {
            let impactMed = UIImpactFeedbackGenerator(style: .heavy)
            impactMed.impactOccurred()
            isMessageActionSheetPresented = true
        }
        .sheet(isPresented: $isMessageActionSheetPresented) {
            MessageActionSheet(viewModel: viewModel, message: $message, conversationPath: nil)
                .presentationDetents([.height(350), .large])
        }
    }

    @ViewBuilder
    func bottom(message: BaseMessage, proxy: ScrollViewProxy) -> some View {
        if let message = message as? Message {
            Divider()
            VStack {
                let sortedArray = (message.answers ?? []).sorted(by: { $0.creationDate ?? .tomorrow < $1.creationDate ?? .yesterday })
                ForEach(Array(sortedArray.enumerated()), id: \.1) { index, answerMessage in
                    MessageCellWrapper(
                        viewModel: viewModel,
                        answerMessage: answerMessage,
                        showHeader: (index == 0 ? true : shouldShowHeader(message: answerMessage, previousMessage: sortedArray[index - 1])))
                }
                Spacer()
                    .id("bottom")
                    .onAppear {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                    .onChange(of: message.answers) {
                        withAnimation {
                            if let id = viewModel.shouldScrollToId {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
            }
            .padding(.horizontal, .l)
        }
    }

    func reloadMessage() async {
        viewModel.shouldScrollToId = "bottom"
        guard let messageId else { return }
        let result = await viewModel.loadMessage(messageId: messageId)
        switch result {
        case .loading:
            message = .loading
        case .failure(let error):
            message = .failure(error: error)
        case .done(let response):
            message = .done(response: response)
            viewRerenderWorkaround.toggle()
        }
    }

    // header is not shown if same person messages multiple times within 5 minutes
    func shouldShowHeader(message: AnswerMessage, previousMessage: AnswerMessage) -> Bool {
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
            if let keys = viewModel.dailyMessages.value?.keys {
                let answerMessage: AnswerMessage? = keys.compactMap { key in
                    if let messageIndex = viewModel.dailyMessages.value?[key]?.firstIndex(where: { $0.answers?.contains(where: { $0.id == self.answerMessage.id }) ?? false }),
                       let answerMessage = viewModel.dailyMessages.value?[key]?[messageIndex].answers?.first(where: { $0.id == self.answerMessage.id }) {
                        return answerMessage
                    }
                    return nil
                }.first
                if let answerMessage {
                    return .done(response: answerMessage)
                }
            }
            return .loading
        }, set: { newValue in
            if let keys = viewModel.dailyMessages.value?.keys {
                keys.forEach { key in
                    if let messageIndex = viewModel.dailyMessages.value?[key]?.firstIndex(where: { $0.answers?.contains(where: { $0.id == answerMessage.id }) ?? false }),
                       let answerMessageIndex = viewModel.dailyMessages.value?[key]?[messageIndex].answers?.firstIndex(where: { $0.id == answerMessage.id }),
                       let newAnswerMessage = newValue.value as? AnswerMessage {
                        viewModel.dailyMessages.value?[key]?[messageIndex].answers?[answerMessageIndex] = newAnswerMessage
                        return
                    }
                }
            }
        })
    }

    var body: some View {
        MessageCell(viewModel: viewModel,
                    message: answerMessageBinding,
                    conversationPath: nil,
                    showHeader: showHeader)
    }
}

#Preview {
    MessageDetailView(
        viewModel: ConversationViewModel.init(
            courseId: 1,
            conversationId: 1),
        message: Binding<DataState<BaseMessage>>.constant(
            DataState<BaseMessage>.done(response: {
                var author = ConversationUser(id: 1)
                author.name = "Alice"
                var message = Message(id: 1)
                message.author = author
                message.content = "Hi, Bob!"
                return message
            }())))
}
