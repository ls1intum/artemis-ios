//
//  MessageCell.swift
//  
//
//  Created by Sven Andabaka on 12.04.23.
//

import ArtemisMarkdown
import Common
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI
import UserStore

struct MessageCell: View {

    @EnvironmentObject var navigationController: NavigationController

    @ObservedObject var viewModel: ConversationViewModel

    @Binding var message: DataState<BaseMessage>

    @State private var showMessageActionSheet = false
    @State private var isPressed = false

    var author: String {
        message.value?.author?.name ?? ""
    }
    var creationDate: Date? {
        message.value?.creationDate
    }
    var content: String {
        message.value?.content ?? ""
    }

    let conversationPath: ConversationPath?
    let showHeader: Bool

    var body: some View {
        HStack(alignment: .top, spacing: .m) {
            Image(systemName: "person")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(.top, .s)
                .opacity(showHeader ? 1 : 0)
            VStack(alignment: .leading, spacing: .xs) {
                if showHeader {
                    HStack(alignment: .firstTextBaseline, spacing: .m) {
                        Text(author)
                            .bold()
                        if let creationDate {
                            Text(creationDate, formatter: DateFormatter.timeOnly)
                                .font(.caption)
                            if content.contains("new")
//                                let lastReadDate = conversationPath?.conversation?.baseConversation.lastReadDate,
//                                lastReadDate < creationDate,
//                                UserSession.shared.user?.id != message.value?.author?.id
                            {
                                Chip(
                                    text: R.string.localizable.new(),
                                    backgroundColor: .Artemis.artemisBlue,
                                    padding: .s
                                )
                                .font(.footnote)
                                .opacity(0)
                            }
                        }
                    }
                }

                ArtemisMarkdownView(string: content)

                if message.value?.updatedDate != nil {
                    Text(R.string.localizable.edited())
                        .foregroundColor(.Artemis.secondaryLabel)
                        .font(.footnote)
                }

                ReactionsView(viewModel: viewModel, message: $message, showEmojiAddButton: false)

                if let message = message.value as? Message,
                   let answerCount = message.answers?.count,
                   let conversationPath,
                   answerCount > 0 {
                    Button(R.string.localizable.replyAction(answerCount)) {
                        if let messagePath = MessagePath(
                            message: self.$message,
                            coursePath: conversationPath.coursePath,
                            conversationPath: conversationPath,
                            conversationViewModel: viewModel
                        ) {
                            navigationController.path.append(messagePath)
                        } else {
                            viewModel.presentError(userFacingError: UserFacingError(title: R.string.localizable.detailViewCantBeOpened()))
                        }
                    }
                }
            }.id(message.value?.id.description)
            Spacer()
        }
        .padding(.horizontal, .l)
        .contentShape(Rectangle())
        .background(isPressed ? Color.Artemis.messsageCellPressed : Color.clear)
        .onTapGesture {
            if let conversationPath, let messagePath = MessagePath(
                message: $message,
                coursePath: conversationPath.coursePath,
                conversationPath: conversationPath,
                conversationViewModel: viewModel
            ) {
                navigationController.path.append(messagePath)
            }
        }
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 30) {
            guard let conversation = viewModel.conversation.value else {
                return
            }
            if let channel = conversation.baseConversation as? Channel, channel.isArchived ?? false {
                return
            }

            let impactMed = UIImpactFeedbackGenerator(style: .heavy)
            impactMed.impactOccurred()
            showMessageActionSheet = true
            isPressed = false
        } onPressingChanged: { pressed in
            isPressed = pressed
        }
        .sheet(isPresented: $showMessageActionSheet) {
            MessageActionSheet(viewModel: viewModel, message: $message, conversationPath: conversationPath)
                .presentationDetents([.height(350), .large])
        }
    }
}

#Preview {
    ForEach([
        "Hi - new",
        """
        Hello, world!
        
        Bye…
        """,
    ], id: \.self) { content in
        MessageCell(
            viewModel: ConversationViewModel.init(courseId: 0, conversationId: 0),
            message: Binding.constant(DataState<BaseMessage>.done(response: {
                var author = ConversationUser.init(id: 0)
                author.name = "Alice"

                var message = Message(id: 1)
                message.author = author
                message.content = content
                message.creationDate = Date.now

                return message
            }())),
            conversationPath: ConversationPath?.none,
            showHeader: true
        )
        .environmentObject(NavigationController())
    }
}
