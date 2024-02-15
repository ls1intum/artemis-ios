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

    @State private var isActionSheetPresented = false
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

    var user: () -> User? = { UserSession.shared.user }

    let conversationPath: ConversationPath?
    let isHeaderVisible: Bool

    var body: some View {
        HStack(alignment: .top, spacing: .m) {
            Image(systemName: "person")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(.top, .s)
                .opacity(isHeaderVisible ? 1 : 0)
            VStack(alignment: .leading, spacing: .xs) {
                if isHeaderVisible {
                    HStack(alignment: .firstTextBaseline, spacing: .m) {
                        Text(author)
                            .bold()
                        if let creationDate {
                            Text(creationDate, formatter: DateFormatter.timeOnly)
                                .font(.caption)
                            Chip(
                                text: R.string.localizable.new(),
                                backgroundColor: .Artemis.artemisBlue,
                                padding: .s
                            )
                            .font(.footnote)
                            .opacity(isChipVisible(creationDate: creationDate) ? 1 : 0)
                        }
                    }
                }

                ArtemisMarkdownView(string: content)

                if message.value?.updatedDate != nil {
                    Text(R.string.localizable.edited())
                        .foregroundColor(.Artemis.secondaryLabel)
                        .font(.footnote)
                }

                ReactionsView(viewModel: viewModel, message: $message, isEmojiPickerButtonVisible: false)

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
            }
            .id(message.value?.id.description)
            Spacer()
        }
        .padding(.horizontal, .l)
        .contentShape(Rectangle())
        .background(isPressed ? Color.Artemis.messsageCellPressed : Color.clear)
        .onTapGesture(perform: onTapPresentMessage)
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 30, perform: onLongPressPresentActionSheet) { pressed in
            isPressed = pressed
        }
        .sheet(isPresented: $isActionSheetPresented) {
            MessageActionSheet(viewModel: viewModel, message: $message, conversationPath: conversationPath)
                .presentationDetents([.height(350), .large])
        }
    }
}

private extension MessageCell {
    func isChipVisible(creationDate: Date) -> Bool {
        guard let lastReadDate = conversationPath?.conversation?.baseConversation.lastReadDate else {
            return false
        }

        return lastReadDate < creationDate && user()?.id != message.value?.author?.id
    }

    func onTapPresentMessage() {
        if let conversationPath, let messagePath = MessagePath(
            message: $message,
            coursePath: conversationPath.coursePath,
            conversationPath: conversationPath,
            conversationViewModel: viewModel
        ) {
            navigationController.path.append(messagePath)
        }
    }

    func onLongPressPresentActionSheet() {
        guard let conversation = viewModel.conversation.value else {
            return
        }
        if let channel = conversation.baseConversation as? Channel, channel.isArchived ?? false {
            return
        }

        let impactMed = UIImpactFeedbackGenerator(style: .heavy)
        impactMed.impactOccurred()
        isActionSheetPresented = true
        isPressed = false
    }
}

#Preview {
    MessageCell(
        viewModel: ConversationViewModel(
            course: MessagesServiceStub.course,
            conversation: MessagesServiceStub.conversation),
        message: Binding.constant(DataState<BaseMessage>.done(response: MessagesServiceStub.message)),
        conversationPath: ConversationPath(
            conversation: MessagesServiceStub.conversation,
            coursePath: CoursePath(course: MessagesServiceStub.course)
        ),
        isHeaderVisible: true
    )
}
