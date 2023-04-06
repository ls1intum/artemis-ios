//
//  ConversationView.swift
//  
//
//  Created by Sven Andabaka on 05.04.23.
//

import SwiftUI
import SharedModels
import DesignLibrary

struct ConversationView: View {

    @StateObject private var viewModel: ConversationViewModel

    init(courseId: Int, conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(courseId: courseId, conversation: conversation))
    }

    var body: some View {
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
                                                   messages: dailyMessage.value)
                        }
                        Spacer()
                    }
                }
            }
                .padding(.horizontal, .l)
        }
            .navigationTitle(viewModel.conversation.baseConversation.conversationName)
            .task {
                await viewModel.loadMessages()
            }
    }
}

private struct ConversationDaySection: View {
    let day: Date
    let messages: [Message]

    var body: some View {
        VStack(alignment: .leading) {
            Text(day, formatter: DateFormatter.dateOnly)
                .font(.headline)
            Divider()
            ForEach(messages, id: \.id) { message in
                MessageCell(message: message)
            }
        }
    }
}

private struct MessageCell: View {
    let message: Message

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
                Text(message.content ?? "")
            }
            Spacer()
        }
    }
}

extension Date: Identifiable {
    public var id: Date {
        return self
    }
}
