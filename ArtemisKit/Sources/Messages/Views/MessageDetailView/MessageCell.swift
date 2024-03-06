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
    @State private var isDetectingLongPress = false

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
                .frame(width: 40, height: isHeaderVisible ? 40 : 0)
                .padding(.top, .s)
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

                ReactionsView(viewModel: viewModel, message: $message)

                if let message = message.value as? Message,
                   let answerCount = message.answers?.count, answerCount > 0,
                   let conversationPath {
                    Button("^[\(answerCount) \(R.string.localizable.reply())](inflect: true)") {
                        if let messagePath = MessagePath(
                            message: self.$message,
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
            .background {
                RoundedRectangle(cornerRadius: .m)
                    .foregroundStyle(
                        (isDetectingLongPress || isActionSheetPresented) ? Color.Artemis.messsageCellPressed : Color.clear)
            }
            .id(message.value?.id.description)
        }
        .padding(.horizontal, .l)
        .contentShape(.rect)
        .onTapGesture(perform: onTapPresentMessage)
        .onLongPressGesture(perform: onLongPressPresentActionSheet) { changed in
            isDetectingLongPress = changed
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

    // MARK: Gestures

    func onTapPresentMessage() {
        // Tap is disabled, if conversation path is nil, e.g., in the message detail view.
        if let conversationPath, let messagePath = MessagePath(
            message: $message,
            conversationPath: conversationPath,
            conversationViewModel: viewModel
        ) {
            navigationController.path.append(messagePath)
        }
    }

    func onLongPressPresentActionSheet() {
        if let channel = viewModel.conversation.baseConversation as? Channel, channel.isArchived ?? false {
            return
        }

        let impactMed = UIImpactFeedbackGenerator(style: .heavy)
        impactMed.impactOccurred()
        isActionSheetPresented = true
        isDetectingLongPress = false
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
