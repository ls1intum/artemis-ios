//
//  ConversationView.swift
//  
//
//  Created by Sven Andabaka on 05.04.23.
//

import SwiftUI
import SharedModels
import DesignLibrary
import Navigation
import Common
import ArtemisMarkdown

// swiftlint:disable:next identifier_name
private let MAX_MINUTES_FOR_GROUPING_MESSAGES = 5

public struct ConversationView: View {

    @StateObject private var viewModel: ConversationViewModel

    public init(courseId: Int, conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(courseId: courseId, conversation: conversation))
    }

    public init(courseId: Int, conversationId: Int64) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(courseId: courseId, conversationId: conversationId))
    }

    private var conversationPath: ConversationPath {
        if let conversation = viewModel.conversation.value {
            return ConversationPath(conversation: conversation, coursePath: CoursePath(id: viewModel.courseId))
        }
        return ConversationPath(id: viewModel.conversationId, coursePath: CoursePath(id: viewModel.courseId))
    }

    public var body: some View {
        VStack {
            ScrollViewReader { value in
                ScrollView {
                    PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                        await viewModel.loadFurtherMessages()
                    }
                    VStack(alignment: .leading) {
                        DataStateView(data: $viewModel.dailyMessages,
                                      retryHandler: { await viewModel.loadMessages() }) { dailyMessages in
                            if dailyMessages.isEmpty {
                                Text(R.string.localizable.noMessagesYet())
                                    .padding(.vertical, .xl)
                                    .padding(.horizontal, .l)
                            } else {
                                ForEach(dailyMessages.sorted(by: { $0.key < $1.key }), id: \.key) { dailyMessage in
                                    ConversationDaySection(viewModel: viewModel,
                                                           day: dailyMessage.key,
                                                           messages: dailyMessage.value,
                                                           conversationPath: conversationPath)
                                }
                                Spacer()
                                    .id("bottom")
                            }
                        }
                    }
                }
                    .coordinateSpace(name: "pullToRefresh")
                    .onChange(of: viewModel.dailyMessages.value) { _ in
                        // TODO: does not work correctly when loadFurtherMessages is called -> is called to early -> investigate
                        if let id = viewModel.shouldScrollToId {
                            withAnimation {
                                value.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
            }
            if !((viewModel.conversation.value?.baseConversation as? Channel)?.isArchived ?? false) {
                SendMessageView(viewModel: viewModel, sendMessageType: .message)
            }
        }
            .navigationTitle(viewModel.conversation.value?.baseConversation.conversationName ?? R.string.localizable.loading())
            .task {
                viewModel.shouldScrollToId = "bottom"
                if viewModel.dailyMessages.value == nil {
                    await viewModel.loadMessages()
                }
            }
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }
}

private struct ConversationDaySection: View {

    @ObservedObject var viewModel: ConversationViewModel

    let day: Date
    let messages: [Message]
    let conversationPath: ConversationPath

    var body: some View {
        VStack(alignment: .leading) {
            Text(day, formatter: DateFormatter.dateOnly)
                .font(.headline)
                .padding(.top, .m)
                .padding(.horizontal, .l)
            Divider()
                .padding(.horizontal, .l)
            ForEach(Array(messages.enumerated()), id: \.1.id) { index, message in
                MessageCellWrapper(viewModel: viewModel,
                                   day: day,
                                   message: message,
                                   conversationPath: conversationPath,
                                   showHeader: (index == 0 ? true : shouldShowHeader(message: message, previousMessage: messages[index - 1])))
            }
        }
    }

    // header is not shown if same person messages multiple times within 5 minutes
    private func shouldShowHeader(message: Message, previousMessage: Message) -> Bool {
        !(message.author == previousMessage.author &&
          message.creationDate ?? .now < (previousMessage.creationDate ?? .yesterday).addingTimeInterval(TimeInterval(MAX_MINUTES_FOR_GROUPING_MESSAGES * 60)))
    }
}

private struct MessageCellWrapper: View {
    @ObservedObject var viewModel: ConversationViewModel

    let day: Date
    let message: Message
    let conversationPath: ConversationPath
    let showHeader: Bool

    private var messageBinding: Binding<DataState<BaseMessage>> {
        Binding(get: {
            if  let messageIndex = viewModel.dailyMessages.value?[day]?.firstIndex(where: { $0.id == message.id }),
                let message = viewModel.dailyMessages.value?[day]?[messageIndex] {
                return .done(response: message)
            }
            return .loading
        }, set: {
            if  let messageIndex = viewModel.dailyMessages.value?[day]?.firstIndex(where: { $0.id == message.id }),
                let newMessage = $0.value as? Message {
                viewModel.dailyMessages.value?[day]?[messageIndex] = newMessage
            }
        })
    }

    var body: some View {
        MessageCell(viewModel: viewModel,
                    message: messageBinding,
                    conversationPath: conversationPath,
                    showHeader: showHeader)
    }
}

extension Date: Identifiable {
    public var id: Date {
        return self
    }
}

private struct PullToRefresh: View {

    var coordinateSpaceName: String
    var onRefresh: () async -> Void

    @State var needRefresh = false

    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: .named(coordinateSpaceName)).midY > 50 {
                Spacer()
                    .onAppear {
                        needRefresh = true
                        Task {
                            await onRefresh()
                            needRefresh = false
                        }
                    }
            }
            HStack {
                Spacer()
                if needRefresh {
                    ProgressView()
                } else {
                    EmptyView()
                }
                Spacer()
            }
        }.padding(.top, -50)
    }
}
