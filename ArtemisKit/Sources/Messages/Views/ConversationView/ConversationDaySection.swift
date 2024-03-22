//
//  ConversationDaySection.swift
//
//
//  Created by Nityananda Zbil on 07.03.24.
//

import Common
import Navigation
import SharedModels
import SwiftUI

struct ConversationDaySection: View {
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
                MessageCellWrapper(
                    viewModel: viewModel,
                    day: day,
                    message: message,
                    conversationPath: conversationPath,
                    isHeaderVisible: index == 0 || !message.isContinuation(of: messages[index - 1]))
            }
        }
    }
}

private struct MessageCellWrapper: View {
    @ObservedObject var viewModel: ConversationViewModel

    let day: Date
    let message: Message
    let conversationPath: ConversationPath
    let isHeaderVisible: Bool

    private var messageBinding: Binding<DataState<BaseMessage>> {
        Binding(get: {
            if  let messageIndex = viewModel.dailyMessages[day]?.firstIndex(where: { $0.id == message.id }),
                let message = viewModel.dailyMessages[day]?[messageIndex] {
                return .done(response: message)
            }
            return .loading
        }, set: {
            if  let messageIndex = viewModel.dailyMessages[day]?.firstIndex(where: { $0.id == message.id }),
                let newMessage = $0.value as? Message {
                viewModel.dailyMessages[day]?[messageIndex] = newMessage
            }
        })
    }

    var body: some View {
        MessageCell(
            viewModel: viewModel,
            message: messageBinding,
            conversationPath: conversationPath,
            isHeaderVisible: isHeaderVisible)
    }
}

#Preview {
    ConversationDaySection(
        viewModel: {
            let viewModel = ConversationViewModel(
                course: MessagesServiceStub.course,
                conversation: MessagesServiceStub.conversation)
            viewModel.dailyMessages = [
                MessagesServiceStub.now: [
                    MessagesServiceStub.message,
                    MessagesServiceStub.continuation,
                    MessagesServiceStub.reply
                ]
            ]
            return viewModel
        }(),
        day: MessagesServiceStub.now,
        messages: [
            MessagesServiceStub.message,
            MessagesServiceStub.continuation,
            MessagesServiceStub.reply
        ],
        conversationPath: ConversationPath(id: 1, coursePath: CoursePath(course: MessagesServiceStub.course))
    )
}
