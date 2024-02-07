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

    @State private var internalMessage: BaseMessage?

    init(viewModel: ConversationViewModel, message: Binding<DataState<BaseMessage>>) {
        self.viewModel = viewModel
        self.messageId = message.wrappedValue.value?.id
        self._message = message
    }

    init(viewModel: ConversationViewModel, messageId: Int64) {
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

    var body: some View {
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
                    SendMessageView(
                        viewModel: viewModel,
                        sendMessageType: .answerMessage(message, { await reloadMessage() }))
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
                let sortedArray = (message.answers ?? []).sorted {
                    $0.creationDate ?? .tomorrow < $1.creationDate ?? .yesterday
                }
                ForEach(Array(sortedArray.enumerated()), id: \.1) { index, answerMessage in
                    let showHeader = index == 0 || !answerMessage.isContinuation(of: sortedArray[index - 1])
                    MessageCellWrapper(
                        viewModel: viewModel,
                        answerMessage: answerMessage,
                        isHeaderVisible: showHeader)
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
                        break
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
    {
        let now = Date.now

        let answer: AnswerMessage = {
            var author = ConversationUser(id: 2)
            author.name = "Bob"
            var answer = AnswerMessage(id: 2)
            answer.author = author
            answer.creationDate = Calendar.current.date(byAdding: .minute, value: 1, to: now)
            answer.content = "How are you?"
            return answer
        }()

        let message: Message = {
            var author = ConversationUser(id: 1)
            author.name = "Alice"
            var message = Message(id: 1)
            message.author = author
            message.creationDate = now
            message.content = "Hi, Bob!"
            message.answers = [answer]
            return message
        }()

        let messagesService = MockMessagesService(messages: [message])
        let viewModel: ConversationViewModel = {
            let viewModel = ConversationViewModel(
                courseId: 1,
                conversationId: 1,
                messagesService: messagesService)
            #warning("Help")
            viewModel.dailyMessages = .done(response: [.now: [message]])
            return viewModel
        }()

        return MessageDetailView(
            viewModel: viewModel,
            message: Binding<DataState<BaseMessage>>.constant(
                DataState<BaseMessage>.done(response: message)))
    }()
}

private struct MockMessagesService: MessagesService {
    let messages: [Message]

    func getConversations(for courseId: Int) async -> Common.DataState<[SharedModels.Conversation]> {
        .loading
    }

    func hideUnhideConversation(for courseId: Int, and conversationId: Int64, isHidden: Bool) async -> Common.NetworkResponse {
        .loading
    }

    func setIsFavoriteConversation(for courseId: Int, and conversationId: Int64, isFavorite: Bool) async -> Common.NetworkResponse {
        .loading
    }

    func getMessages(for courseId: Int, and conversationId: Int64, size: Int) async -> Common.DataState<[SharedModels.Message]> {
        .done(response: messages)
    }

    func sendMessage(for courseId: Int, conversation: SharedModels.Conversation, content: String) async -> Common.NetworkResponse {
        .loading
    }

    func sendAnswerMessage(for courseId: Int, message: SharedModels.Message, content: String) async -> Common.NetworkResponse {
        .loading
    }

    func deleteMessage(for courseId: Int, messageId: Int64) async -> Common.NetworkResponse {
        .loading
    }

    func deleteAnswerMessage(for courseId: Int, anserMessageId: Int64) async -> Common.NetworkResponse {
        .loading
    }

    func editMessage(for courseId: Int, message: SharedModels.Message) async -> Common.NetworkResponse {
        .loading
    }

    func editAnswerMessage(for courseId: Int, answerMessage: SharedModels.AnswerMessage) async -> Common.NetworkResponse {
        .loading
    }

    func addReactionToAnswerMessage(for courseId: Int, answerMessage: SharedModels.AnswerMessage, emojiId: String) async -> Common.NetworkResponse {
        .loading
    }

    func addReactionToMessage(for courseId: Int, message: SharedModels.Message, emojiId: String) async -> Common.NetworkResponse {
        .loading
    }

    func removeReactionFromMessage(for courseId: Int, reaction: SharedModels.Reaction) async -> Common.NetworkResponse {
        .loading
    }

    func getChannelsOverview(for courseId: Int) async -> Common.DataState<[SharedModels.Channel]> {
        .loading
    }

    func addMembersToChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> Common.NetworkResponse {
        .loading
    }

    func removeMembersFromChannel(for courseId: Int, channelId: Int64, usernames: [String]) async -> Common.NetworkResponse {
        .loading
    }

    func addMembersToGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> Common.NetworkResponse {
        .loading
    }

    func removeMembersFromGroupChat(for courseId: Int, groupChatId: Int64, usernames: [String]) async -> Common.NetworkResponse {
        .loading
    }

    func createChannel(for courseId: Int, name: String, description: String?, isPrivate: Bool, isAnnouncement: Bool) async -> Common.DataState<SharedModels.Channel> {
        .loading
    }

    func searchForUsers(for courseId: Int, searchText: String) async -> Common.DataState<[SharedModels.ConversationUser]> {
        .loading
    }

    func createGroupChat(for courseId: Int, usernames: [String]) async -> Common.DataState<SharedModels.GroupChat> {
        .loading
    }

    func createOneToOneChat(for courseId: Int, usernames: [String]) async -> Common.DataState<SharedModels.OneToOneChat> {
        .loading
    }

    func getMembersOfConversation(for courseId: Int, conversationId: Int64, page: Int) async -> Common.DataState<[SharedModels.ConversationUser]> {
        .loading
    }

    func archiveChannel(for courseId: Int, channelId: Int64) async -> Common.NetworkResponse {
        .loading
    }

    func unarchiveChannel(for courseId: Int, channelId: Int64) async -> Common.NetworkResponse {
        .loading
    }
}
