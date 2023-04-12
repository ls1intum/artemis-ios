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
                                    if let conversation = viewModel.conversation.value {
                                        ConversationDaySection(day: dailyMessage.key,
                                                               messages: dailyMessage.value,
                                                               conversationPath: ConversationPath(conversation: conversation,
                                                                                                  coursePath: CoursePath(id: viewModel.courseId)))
                                    } else {
                                        ConversationDaySection(day: dailyMessage.key,
                                                               messages: dailyMessage.value,
                                                               conversationPath: ConversationPath(id: viewModel.conversationId,
                                                                                                  coursePath: CoursePath(id: viewModel.courseId)))
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }
                    .coordinateSpace(name: "pullToRefresh")
                    .onChange(of: viewModel.dailyMessages.value) { dailyMessages in
                        if let dailyMessages,
                           let lastKey = dailyMessages.keys.max(),
                           let lastMessage = dailyMessages[lastKey]?.last {
                            value.scrollTo(lastMessage.id, anchor: .center)
                        }
                    }
            }
            if !((viewModel.conversation.value?.baseConversation as? Channel)?.isArchived ?? false) {
                SendMessageView(viewModel: viewModel, sendMessageType: .message)
            }
        }
            .navigationTitle(viewModel.conversation.value?.baseConversation.conversationName ?? R.string.localizable.loading())
            .task {
                await viewModel.loadMessages()
            }
    }
}

private struct ConversationDaySection: View {
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
                MessageCell(message: message,
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

private struct MessageCell: View {

    @EnvironmentObject var navigationController: NavigationController

    @State private var showMessageActionSheet = false
    @State private var isPressed = false

    let message: Message
    let conversationPath: ConversationPath
    let showHeader: Bool

    var body: some View {
        HStack(alignment: .top, spacing: .l) {
            Image(systemName: "person")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(.top, .s)
                .opacity(showHeader ? 1 : 0)
            VStack(alignment: .leading, spacing: .m) {
                if showHeader {
                    HStack(alignment: .bottom, spacing: .m) {
                        Text(message.author?.name ?? "")
                            .bold()
                        if let creationDate = message.creationDate {
                            Text(creationDate, formatter: DateFormatter.timeOnly)
                                .font(.caption)
                        }
                    }
                }
                ArtemisMarkdownView(string: message.content ?? "")
                ReactionsView(message: message, showEmojiAddButton: false)
                if let answerCount = message.answers?.count,
                   answerCount > 0 {
                    Button(R.string.localizable.replyAction(answerCount)) {
                        navigationController.path.append(MessagePath(message: message, coursePath: conversationPath.coursePath, conversationPath: conversationPath))
                    }
                }
            }.id(message.id)
            Spacer()
        }
            .padding(.horizontal, .l)
            .contentShape(Rectangle())
            .background(isPressed ? Color.Artemis.messsageCellPressed : Color.clear)
            .onTapGesture {
                print("This somehow fixes scrolling...")
            }
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 30, perform: {
                let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                impactMed.impactOccurred()
                showMessageActionSheet = true
                isPressed = false
            }, onPressingChanged: { pressed in
                isPressed = pressed
            })
            .sheet(isPresented: $showMessageActionSheet) {
                MessageActionSheet(message: message, conversationPath: conversationPath)
                    .presentationDetents([.height(350), .large])
            }
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
