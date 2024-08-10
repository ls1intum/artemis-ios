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

struct MessageDetailView: View {

    @ObservedObject var viewModel: ConversationViewModel
    @Binding private var message: DataState<BaseMessage>

    @State private var isMessageActionSheetPresented = false
    @State private var viewRerenderWorkaround = false

    private let messageId: Int64?
    private let presentKeyboardOnAppear: Bool

    init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>, presentKeyboardOnAppear: Bool = false) {
        self.viewModel = viewModel
        self.messageId = message.wrappedValue.value?.id
        self._message = message
        self.presentKeyboardOnAppear = presentKeyboardOnAppear
    }

    var body: some View {
        DataStateView(data: $message) {
            await reloadMessage()
        } content: { message in
            VStack(alignment: .leading, spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        top(message: message)
                        answers(of: message, proxy: proxy)
                    }
                }
                if !((viewModel.conversation.baseConversation as? Channel)?.isArchived ?? false),
                   let message = message as? Message {
                    SendMessageView(
                        viewModel: SendMessageViewModel(
                            course: viewModel.course,
                            conversation: viewModel.conversation,
                            configuration: .answerMessage(message, reloadMessage),
                            delegate: SendMessageViewModelDelegate(viewModel),
                            presentKeyboardOnAppear: presentKeyboardOnAppear
                        )
                    )
                }
            }
        }
        .navigationTitle(R.string.localizable.thread() + " (\(viewModel.conversation.baseConversation.conversationName))")
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
        MessageCell(
            conversationViewModel: viewModel,
            message: Binding.constant(DataState<BaseMessage>.done(response: message)),
            conversationPath: nil,
            isHeaderVisible: true,
            roundBottomCorners: true
        )
        .environment(\.isEmojiPickerButtonVisible, true)
        .environment(\.messageUseFullWidth, true)
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

    @ViewBuilder var divider: some View {
        VStack {
            Divider()
            HStack {
                let replies = (message.value as? Message)?.answers?.count ?? 0
                Text("^[\(replies) \(R.string.localizable.replies())](inflect:true)")
                    .foregroundStyle(.secondary)
                    .padding(.top, .s)

                Spacer()

                // Only display labels if we have enough space
                ViewThatFits(in: .horizontal) {
                    HStack {
                        MessageActions(viewModel: viewModel, message: $message, conversationPath: nil)
                    }
                    HStack(spacing: .l) {
                        MessageActions(viewModel: viewModel, message: $message, conversationPath: nil)
                            .labelStyle(.iconOnly)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(.horizontal)
            Divider()
        }.padding(.top, .s)
    }

    @ViewBuilder
    func answers(of message: BaseMessage, proxy: ScrollViewProxy) -> some View {
        if let message = message as? Message {
            divider

            VStack(spacing: 0) {
                let sortedArray = (message.answers ?? []).sorted {
                    $0.creationDate ?? .tomorrow < $1.creationDate ?? .yesterday
                }
                let totalMessages = sortedArray.count
                ForEach(Array(sortedArray.enumerated()), id: \.1) { index, answerMessage in
                    let isHeaderVisible = !answerMessage.isContinuation(of: sortedArray[safe: index - 1])
                    let needsRoundedCorners = !(sortedArray[safe: index + 1]?.isContinuation(of: answerMessage) ?? false)
                    MessageCellWrapper(
                        viewModel: viewModel,
                        answerMessage: answerMessage,
                        isHeaderVisible: isHeaderVisible,
                        roundBottomCorners: needsRoundedCorners)
                    .id(index == totalMessages - 1 ? nil : answerMessage)
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
            .environment(\.isOriginalMessageAuthor, message.isCurrentUserAuthor)
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
}

private struct MessageCellWrapper: View {

    @ObservedObject var viewModel: ConversationViewModel

    let answerMessage: AnswerMessage
    let isHeaderVisible: Bool
    let roundBottomCorners: Bool

    private var answerMessageBinding: Binding<DataState<BaseMessage>> {

        let isAnswerMessage = { (answer: AnswerMessage) -> Bool in
            answer.id == self.answerMessage.id
        }
        let messageContainsAnswer = { (message: IdentifiableMessage) -> Bool in
            message.rawValue.answers?.contains(where: isAnswerMessage) ?? false
        }

        return Binding {
            if let message = viewModel.messages.first(where: messageContainsAnswer),
               let answer = message.rawValue.answers?.first(where: isAnswerMessage) {
                return .done(response: answer)
            } else {
                return .loading
            }
        } set: { value in
            if var message = viewModel.messages.first(where: messageContainsAnswer)?.rawValue,
               let answer = value.value as? AnswerMessage,
               let index = message.answers?.firstIndex(where: isAnswerMessage) {
                message.answers?[index] = answer
                viewModel.messages.update(with: .message(message))
            }
        }
    }

    var body: some View {
        MessageCell(
            conversationViewModel: viewModel,
            message: answerMessageBinding,
            conversationPath: nil,
            isHeaderVisible: isHeaderVisible,
            roundBottomCorners: roundBottomCorners)
    }
}

#Preview {
    MessageDetailView(
        viewModel: {
            let viewModel = ConversationViewModel(
                course: MessagesServiceStub.course,
                conversation: MessagesServiceStub.conversation)
            viewModel.messages = [
                .message(MessagesServiceStub.message)
            ]
            return viewModel
        }(),
        message: Binding.constant(DataState<BaseMessage>.done(response: MessagesServiceStub.message)))
}
