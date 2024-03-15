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
    @State var viewModel: MessageDetailViewModel
    @ObservedObject var conversationViewModel: ConversationViewModel

    @State private var isMessageActionSheetPresented = false

    var body: some View {
        VStack(alignment: .leading) {
            ScrollViewReader { proxy in
                ScrollView {
                    top(message: viewModel.message)
                    answers(of: viewModel.message, proxy: proxy)
                    MessageOfflineSection(viewModel, conversationViewModel: conversationViewModel)
                }
            }
            Spacer()
            if !((conversationViewModel.conversation.baseConversation as? Channel)?.isArchived ?? false) {
                SendMessageView(
                    viewModel: SendMessageViewModel(
                        course: conversationViewModel.course,
                        conversation: conversationViewModel.conversation,
                        configuration: .answerMessage(viewModel.message, viewModel),
                        delegate: SendMessageViewModelDelegate(conversationViewModel)
                    )
                )
            }
        }
        .task {
            await viewModel.loadMessage()
        }
        .navigationTitle(R.string.localizable.thread())
        .alert(isPresented: $conversationViewModel.showError, error: conversationViewModel.error, actions: {})
    }
}

extension MessageDetailView {
    @available(*, deprecated, message: "Refactor MessagePath")
    init(conversationViewModel: ConversationViewModel, course: Course, conversation: Conversation, message: Message) {
        self.init(
            viewModel: MessageDetailViewModel(course: course, conversation: conversation, message: message),
            conversationViewModel: conversationViewModel)
    }
}

private extension MessageDetailView {
    func top(message: BaseMessage) -> some View {
        MessageCell(
            viewModel: conversationViewModel,
            message: Binding.constant(DataState<BaseMessage>.done(response: message)),
            conversationPath: nil,
            isHeaderVisible: true
        )
        .environment(\.isEmojiPickerButtonVisible, true)
        .onLongPressGesture(maximumDistance: 30) {
            let impactMed = UIImpactFeedbackGenerator(style: .heavy)
            impactMed.impactOccurred()
            isMessageActionSheetPresented = true
        }
        .sheet(isPresented: $isMessageActionSheetPresented) {
            #warning("Constant")
            MessageActionSheet(viewModel: conversationViewModel, message: Binding.constant(.done(response: viewModel.message)), conversationPath: nil)
                .presentationDetents([.height(350), .large])
        }
    }

    @ViewBuilder
    func answers(of message: BaseMessage, proxy: ScrollViewProxy) -> some View {
        if let message = message as? Message {
            Divider()
            VStack {
                let sortedArray = (message.answers ?? []).sorted {
                    $0.creationDate ?? .tomorrow < $1.creationDate ?? .yesterday
                }
                ForEach(Array(sortedArray.enumerated()), id: \.1) { index, answerMessage in
                    MessageCellWrapper(
                        viewModel: conversationViewModel,
                        answerMessage: answerMessage,
                        isHeaderVisible: index == 0 || !answerMessage.isContinuation(of: sortedArray[index - 1]))
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
        }
    }
}

private struct MessageCellWrapper: View {

    @ObservedObject var viewModel: ConversationViewModel

    let answerMessage: AnswerMessage
    let isHeaderVisible: Bool

    private var answerMessageBinding: Binding<DataState<BaseMessage>> {

        let isAnswerMessage = { (answer: AnswerMessage) -> Bool in
            answer.id == self.answerMessage.id
        }
        let messageContainsAnswer = { (message: Message) -> Bool in
            message.answers?.contains(where: isAnswerMessage) ?? false
        }

        return Binding(get: {
            if let dailyMessages = viewModel.dailyMessages.value {
                let answerMessages: [AnswerMessage] = dailyMessages.keys.compactMap { key in

                    if let messages = dailyMessages[key],
                       let messageIndex = messages.firstIndex(where: messageContainsAnswer),
                       let answerMessage = messages[messageIndex].answers?.first(where: isAnswerMessage) {
                        return answerMessage
                    }
                    return nil
                }

                if let answerMessage = answerMessages.first {
                    return .done(response: answerMessage)
                }
            }
            return .loading
        }, set: { newValue in
            if let newAnswerMessage = newValue.value as? AnswerMessage,
               let dailyMessages = viewModel.dailyMessages.value {

                for key in dailyMessages.keys {

                    if let messages = dailyMessages[key],
                       let messageIndex = messages.firstIndex(where: messageContainsAnswer),
                       let answerMessageIndex = messages[messageIndex].answers?.firstIndex(where: isAnswerMessage) {

                        viewModel.dailyMessages.value?[key]?[messageIndex].answers?[answerMessageIndex] = newAnswerMessage
                        continue
                    }
                }
            }
        })
    }

    var body: some View {
        MessageCell(
            viewModel: viewModel,
            message: answerMessageBinding,
            conversationPath: nil,
            isHeaderVisible: isHeaderVisible)
    }
}

#Preview {
    MessageDetailView(
        viewModel: MessageDetailViewModel(
            course: MessagesServiceStub.course,
            conversation: MessagesServiceStub.conversation,
            message: MessagesServiceStub.message),
        conversationViewModel: {
            let viewModel = ConversationViewModel(
                course: MessagesServiceStub.course,
                conversation: MessagesServiceStub.conversation)
            viewModel.dailyMessages = .done(response: [
                MessagesServiceStub.now: [
                    MessagesServiceStub.message
                ]
            ])
            return viewModel
        }()
    )
}
