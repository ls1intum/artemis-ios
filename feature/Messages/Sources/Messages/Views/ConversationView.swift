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

struct ConversationView: View {

    @StateObject private var viewModel: ConversationViewModel

    init(courseId: Int, conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(courseId: courseId, conversation: conversation))
    }

    var body: some View {
        VStack {
            ScrollViewReader { value in
                ScrollView {
                    VStack(alignment: .leading) {
                        DataStateView(data: $viewModel.dailyMessages,
                                      retryHandler: { await viewModel.loadMessages() }) { dailyMessages in
                            if dailyMessages.isEmpty {
                                Text("There are no messages yet! Write the first message to kickstart this conversation.")
                                    .padding(.vertical, .xl)
                            } else {
                                ForEach(dailyMessages.sorted(by: { $0.key < $1.key }), id: \.key) { dailyMessage in
                                    ConversationDaySection(day: dailyMessage.key,
                                                           messages: dailyMessage.value,
                                                           conversationPath: ConversationPath(conversation: viewModel.conversation,
                                                                                              coursePath: CoursePath(id: viewModel.courseId)))
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, .l)
                }
                    .onChange(of: viewModel.dailyMessages.value) { dailyMessages in
                        if let dailyMessages,
                           let lastKey = dailyMessages.keys.max(),
                           let lastMessage = dailyMessages[lastKey]?.last {
                            value.scrollTo(lastMessage.id, anchor: .center)
                        }
                    }
            }
            SendMessageView(viewModel: viewModel)
        }
            .navigationTitle(viewModel.conversation.baseConversation.conversationName)
            .task {
                await viewModel.loadMessages()
            }
            .navigationDestination(for: MessagePath.self) { messagePath in
                // TODO: remove force unwrap
                MessageDetailView(viewModel: viewModel, message: messagePath.message!)
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
            Divider()
            ForEach(messages, id: \.id) { message in
                MessageCell(message: message, conversationPath: conversationPath)
            }
        }
    }
}

private struct MessageCell: View {

    @EnvironmentObject var navigationController: NavigationController

    @State private var showMessageActionSheet = false

    let message: Message
    let conversationPath: ConversationPath

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
                        Text(creationDate, formatter: DateFormatter.timeOnly)
                            .font(.caption)
                    }
                }
                ArtemisMarkdownView(string: message.content ?? "")
                ReactionsView(message: message, showEmojiAddButton: false)
                if let answerCount = message.answers?.count,
                   answerCount > 0 {
                    Button("\(answerCount) reply") {
                        navigationController.path.append(MessagePath(message: message, conversationPath: conversationPath))
                    }
                }
            }.id(message.id)
            Spacer()
        }
            .onTapGesture {
                print("tapped")
            }
            .onLongPressGesture(minimumDuration: 0.3, maximumDistance: 30) {
                showMessageActionSheet = true
            }
            .sheet(isPresented: $showMessageActionSheet) {
                MessageActionSheet(message: message, conversationPath: conversationPath)
                    .presentationDetents([.height(250), .large])
            }
    }
}

extension Date: Identifiable {
    public var id: Date {
        return self
    }
}
