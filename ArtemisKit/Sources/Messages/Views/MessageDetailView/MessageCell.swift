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

@MainActor final class MessageCellModel {
    let course: Course

    private let messagesService: MessagesService

    init(
        course: Course,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self.course = course
        self.messagesService = messagesService
    }

    func getOneToOneChatOrCreate(login: String) async -> Conversation? {
        async let conversations = messagesService.getConversations(for: course.id)
        async let chat = messagesService.createOneToOneChat(for: course.id, usernames: [login])

        if let conversations = await conversations.value,
           let conversation = conversations.first(where: { conversation in
                guard case let .oneToOneChat(conversation) = conversation,
                      let members = conversation.members else {
                    return false
                }
                return members.map(\.login).contains(login)
           }) {
            return conversation
        } else if let chat = await chat.value {
            return Conversation.oneToOneChat(conversation: chat)
        }

        return nil
    }
}

struct MessageCell: View {
    @Environment(\.isMessageOffline) var isMessageOffline: Bool
    @EnvironmentObject var navigationController: NavigationController

    @ObservedObject var viewModel: ConversationViewModel

    @Binding var message: DataState<BaseMessage>

    @State private var isActionSheetPresented = false
    @State private var isDetectingLongPress = false

    var user: () -> User? = { UserSession.shared.user }

    let conversationPath: ConversationPath?
    let isHeaderVisible: Bool

    var retryButtonAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: .m) {
            Image(systemName: "person")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: isHeaderVisible ? 40 : 0)
                .padding(.top, .s)
            VStack(alignment: .leading, spacing: .xs) {
                HStack {
                    VStack(alignment: .leading, spacing: .xs) {
                        headerIfVisible
                        ArtemisMarkdownView(string: content)
                            .opacity(isMessageOffline ? 0.5 : 1)
                            .environment(\.openURL, OpenURLAction(handler: handle))
                    }
                    Spacer()
                }
                .background {
                    RoundedRectangle(cornerRadius: .m)
                        .foregroundStyle(backgroundOnPress)
                }
                .contentShape(.rect)
                .onTapGesture(perform: onTapPresentMessage)
                .onLongPressGesture(perform: onLongPressPresentActionSheet) { changed in
                    isDetectingLongPress = changed
                }

                ReactionsView(viewModel: viewModel, message: $message)
                retryButtonIfAvailable
                replyButtonIfAvailable
            }
            .id(message.value?.id.description)
        }
        .padding(.horizontal, .l)
        .sheet(isPresented: $isActionSheetPresented) {
            MessageActionSheet(viewModel: viewModel, message: $message, conversationPath: conversationPath)
                .presentationDetents([.height(350), .large])
        }
    }
}

enum MentionScheme {
    case channel(Int64)
    case exercise(Int)
    case lecture(Int)
    case member(String)

    init?(_ url: URL) {
        guard url.scheme == "mention" else {
            return nil
        }
        switch url.host() {
        case "channel":
            if let id = Int64(url.lastPathComponent) {
                self = .channel(id)
                return
            }
        case "exercise":
            if let id = Int(url.lastPathComponent) {
                self = .exercise(id)
                return
            }
        case "lecture":
            if let id = Int(url.lastPathComponent) {
                self = .lecture(id)
                return
            }
        case "member":
            self = .member(url.lastPathComponent)
            return
        default:
            return nil
        }
        return nil
    }
}

private extension MessageCell {
    func handle(url: URL) -> OpenURLAction.Result {
        if let mention = MentionScheme(url) {
            let coursePath = CoursePath(course: viewModel.course)
            switch mention {
            case let .channel(id):
                navigationController.path.append(ConversationPath(id: id, coursePath: coursePath))
            case let .exercise(id):
                navigationController.path.append(ExercisePath(id: id, coursePath: coursePath))
            case let .lecture(id):
                navigationController.path.append(LecturePath(id: id, coursePath: coursePath))
            case let .member(login):
                Task {
                    let viewModel = MessageCellModel(course: viewModel.course)
                    if let conversation = await viewModel.getOneToOneChatOrCreate(login: login) {
                        navigationController.path.append(ConversationPath(conversation: conversation, coursePath: coursePath))
                    }
                }
            }
            return .handled
        }
        return .systemAction
    }

    var author: String {
        message.value?.author?.name ?? ""
    }

    var creationDate: Date? {
        message.value?.creationDate
    }

    var content: String {
        message.value?.content ?? ""
    }

    var backgroundOnPress: Color {
        (isDetectingLongPress || isActionSheetPresented) ? Color.Artemis.messsageCellPressed : Color.clear
    }

    @ViewBuilder var headerIfVisible: some View {
        if isHeaderVisible {
            HStack(alignment: .firstTextBaseline, spacing: .m) {
                Text(isMessageOffline ? "Redacted" : author)
                    .bold()
                    .redacted(reason: isMessageOffline ? .placeholder : [])
                if let creationDate {
                    Group {
                        Text(creationDate, formatter: DateFormatter.timeOnly)

                        if message.value?.updatedDate != nil {
                            Text(R.string.localizable.edited())
                                .foregroundColor(.Artemis.secondaryLabel)
                        }
                    }
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
    }

    func isChipVisible(creationDate: Date) -> Bool {
        guard let lastReadDate = conversationPath?.conversation?.baseConversation.lastReadDate else {
            return false
        }

        return lastReadDate < creationDate && user()?.id != message.value?.author?.id
    }

    @ViewBuilder var retryButtonIfAvailable: some View {
        if let retryButtonAction {
            Button(action: retryButtonAction) {
                Label {
                    Text("Failed to send")
                } icon: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .foregroundStyle(.red)
        }
    }

    @ViewBuilder var replyButtonIfAvailable: some View {
        if let message = message.value as? Message,
           let answerCount = message.answers?.count, answerCount > 0,
           let conversationPath {
            Button {
                if let messagePath = MessagePath(
                    message: self.$message,
                    conversationPath: conversationPath,
                    conversationViewModel: viewModel
                ) {
                    navigationController.path.append(messagePath)
                } else {
                    viewModel.presentError(userFacingError: UserFacingError(title: R.string.localizable.detailViewCantBeOpened()))
                }
            } label: {
                Label {
                    Text("^[\(answerCount) \(R.string.localizable.reply())](inflect: true)")
                } icon: {
                    Image(systemName: "arrow.turn.down.right")
                }
            }
        }
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

        let feedback = UIImpactFeedbackGenerator(style: .heavy)
        feedback.impactOccurred()
        isActionSheetPresented = true
        isDetectingLongPress = false
    }
}

// MARK: - Environment+IsMessageOffline

private enum IsMessageOfflineEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isMessageOffline: Bool {
        get {
            self[IsMessageOfflineEnvironmentKey.self]
        }
        set {
            self[IsMessageOfflineEnvironmentKey.self] = newValue
        }
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
