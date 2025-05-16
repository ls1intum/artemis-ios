//
//  ForwardedMessageView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 16.05.25.
//

import ArtemisMarkdown
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

struct ForwardedMessageView: View {
    @ObservedObject var viewModel: ConversationViewModel
    let message: Message?

    var body: some View {
        if let message, message.hasForwardedMessages ?? false,
           let forwardedDTO = viewModel.forwardedSourcePosts.first(where: { $0.id == message.id }) {
               if let sourceMessage = forwardedDTO.sourceMessage {
                   ForwardedMessageCell(message: sourceMessage)
               } else {
                   ArtemisHintBox(text: "Forwarded message not found", hintType: .warning)
               }
        }
    }
}

private struct ForwardedMessageCell: View {
    @EnvironmentObject var navController: NavigationController
    let message: BaseMessage

    var body: some View {
        HStack {
            Capsule()
                .foregroundStyle(Color.Artemis.artemisBlue)
                .frame(width: .s)

            VStack(alignment: .leading) {
                forwardedFromHeader
                messageHeader
                ArtemisMarkdownView(string: message.content ?? "")
                    .frame(maxHeight: .largeImage)
                    .allowsHitTesting(false)
                    .offset(y: -5) // There is more space by default than we want
            }
            .padding([.vertical, .trailing], .s)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: .s))
        .contentShape(.rect)
        .onTapGesture {
            if let conversation, let coursePath = navController.selectedCourse, let baseThreadId {
                let threadPath = ThreadPath(postId: baseThreadId, conversation: conversation, coursePath: coursePath)
                navController.tabPath.append(threadPath)
            }
        }
    }

    var conversation: Conversation? {
        if let message = message as? Message {
            return message.conversation
        }
        if let message = message as? AnswerMessage,
           let parent = message.post {
            return parent.conversation
        }
        return nil
    }

    var baseThreadId: Int64? {
        if let message = message as? Message {
            return message.id
        }
        if let message = message as? AnswerMessage,
           let parent = message.post {
            return parent.id
        }
        return nil
    }

    @ViewBuilder var forwardedFromHeader: some View {
        if let conversationName = conversation?.baseConversation.conversationName {
            HStack {
                Text("Forwarded from #\(conversationName)")

                Spacer()

                if let creationDate = message.creationDate {
                    Text(creationDate, formatter: DateFormatter.superShortDateAndTime)
                }
            }
            .font(.caption)
        }
    }

    @ViewBuilder var messageHeader: some View {
        if let author = message.author {
            HStack(spacing: .s) {
                ProfilePictureView(user: author, role: nil, course: .mock, size: 25)
                    .allowsHitTesting(false)
                Text(author.name ?? "")
                    .fontWeight(.medium)
            }
        }
    }
}
