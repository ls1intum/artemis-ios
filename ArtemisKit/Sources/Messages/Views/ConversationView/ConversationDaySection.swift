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
    var conversationPath: ConversationPath {
        ConversationPath(conversation: viewModel.conversation, coursePath: CoursePath(course: viewModel.course))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(day, formatter: DateFormatter.dateOnly)
                .font(.headline)
                .padding(.vertical, .m)
                .padding(.horizontal, .l)
            Divider()
                .padding(.horizontal, .l)
                .padding(.bottom, .s)
            ForEach(Array(messages.enumerated()), id: \.1.id) { index, message in
                let needsRoundedCorners = !(messages[safe: index + 1]?.isContinuation(of: message) ?? false)
                MessageCellWrapper(
                    viewModel: viewModel,
                    day: day,
                    message: message,
                    conversationPath: conversationPath,
                    isHeaderVisible: !message.isContinuation(of: messages[safe: index - 1]),
                    roundBottomCorners: needsRoundedCorners)
                .id(index == messages.count - 1 ? nil : message.id)
            }
        }
        .id(messages)
    }
}

private struct MessageCellWrapper: View {
    @ObservedObject var viewModel: ConversationViewModel

    let day: Date
    let message: Message
    let conversationPath: ConversationPath
    let isHeaderVisible: Bool
    let roundBottomCorners: Bool

    private var messageBinding: Binding<DataState<BaseMessage>> {
        Binding {
            if let index = viewModel.messages.firstIndex(of: .of(id: message.id)) {
                return .done(response: viewModel.messages[index].rawValue)
            } else {
                return .loading
            }
        } set: { value in
            if let message = value.value as? Message {
                viewModel.messages.update(with: .message(message))
            }
        }
    }

    var body: some View {
        MessageCell(
            conversationViewModel: viewModel,
            message: messageBinding,
            conversationPath: conversationPath,
            isHeaderVisible: isHeaderVisible,
            roundBottomCorners: roundBottomCorners)
    }
}

#Preview {
    ConversationDaySection(
        viewModel: {
            let viewModel = ConversationViewModel(
                course: MessagesServiceStub.course,
                conversation: MessagesServiceStub.conversation)
            viewModel.messages = [
                .message(MessagesServiceStub.message),
                .message(MessagesServiceStub.continuation),
                .message(MessagesServiceStub.reply)
            ]
            return viewModel
        }(),
        day: MessagesServiceStub.now,
        messages: [
            MessagesServiceStub.message,
            MessagesServiceStub.continuation,
            MessagesServiceStub.reply
        ]
    )
}
