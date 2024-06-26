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

struct MessageCell: View {
    @Environment(\.isMessageOffline) var isMessageOffline: Bool
    @EnvironmentObject var navigationController: NavigationController

    @ObservedObject var conversationViewModel: ConversationViewModel

    @Binding var message: DataState<BaseMessage>

    @State var viewModel: MessageCellModel

    var body: some View {
        HStack(alignment: .top, spacing: .m) {
            Image(systemName: "person")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: viewModel.isHeaderVisible ? 40 : 0)
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
                    viewModel.isDetectingLongPress = changed
                }

                ReactionsView(viewModel: conversationViewModel, message: $message)
                retryButtonIfAvailable
                replyButtonIfAvailable
            }
            .id(message.value?.id.description)
        }
        .padding(.horizontal, .l)
        .sheet(isPresented: $viewModel.isActionSheetPresented) {
            MessageActionSheet(
                viewModel: conversationViewModel,
                message: $message,
                conversationPath: viewModel.conversationPath
            )
            .presentationDetents([.height(350), .large])
        }
    }
}

extension MessageCell {
    init(
        conversationViewModel: ConversationViewModel,
        message: Binding<DataState<BaseMessage>>,
        conversationPath: ConversationPath?,
        isHeaderVisible: Bool,
        retryButtonAction: (() -> Void)? = nil
    ) {
        self.init(
            conversationViewModel: conversationViewModel,
            message: message,
            viewModel: MessageCellModel(
                course: conversationViewModel.course,
                conversationPath: conversationPath,
                isHeaderVisible: isHeaderVisible,
                retryButtonAction: retryButtonAction)
        )
    }
}

private extension MessageCell {
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
        (viewModel.isDetectingLongPress || viewModel.isActionSheetPresented) ? Color.Artemis.messsageCellPressed : Color.clear
    }

    @ViewBuilder var headerIfVisible: some View {
        if viewModel.isHeaderVisible {
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
                    .opacity(
                        viewModel.isChipVisible(creationDate: creationDate, authorId: message.value?.author?.id) ? 1 : 0
                    )
                }
            }
        }
    }

    @ViewBuilder var retryButtonIfAvailable: some View {
        if let retryButtonAction = viewModel.retryButtonAction {
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
           let conversationPath = viewModel.conversationPath {
            Button {
                if let messagePath = MessagePath(
                    message: self.$message,
                    conversationPath: conversationPath,
                    conversationViewModel: conversationViewModel
                ) {
                    navigationController.path.append(messagePath)
                } else {
                    conversationViewModel.presentError(userFacingError: UserFacingError(title: R.string.localizable.detailViewCantBeOpened()))
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
        if let conversationPath = viewModel.conversationPath, let messagePath = MessagePath(
            message: $message,
            conversationPath: conversationPath,
            conversationViewModel: conversationViewModel
        ) {
            navigationController.path.append(messagePath)
        }
    }

    func onLongPressPresentActionSheet() {
        if let channel = conversationViewModel.conversation.baseConversation as? Channel, channel.isArchived ?? false {
            return
        }

        let feedback = UIImpactFeedbackGenerator(style: .heavy)
        feedback.impactOccurred()
        viewModel.isActionSheetPresented = true
        viewModel.isDetectingLongPress = false
    }

    func handle(url: URL) -> OpenURLAction.Result {
        if let mention = MentionScheme(url) {
            let coursePath = CoursePath(course: conversationViewModel.course)
            switch mention {
            case let .attachment(id, lectureId):
                navigationController.path.append(LecturePath(id: lectureId, coursePath: coursePath))
            case let .channel(id):
                navigationController.path.append(ConversationPath(id: id, coursePath: coursePath))
            case let .exercise(id):
                navigationController.path.append(ExercisePath(id: id, coursePath: coursePath))
            case let .lecture(id):
                navigationController.path.append(LecturePath(id: id, coursePath: coursePath))
            case let .lectureUnit(id, attachmentUnit):
                Task {
                    let vm = SendMessageLecturePickerViewModel(
                        course: conversationViewModel.course,
                        delegate: SendMessageMentionContentDelegate { _ in })

                    await vm.loadLecturesWithSlides()

                    for lecture in vm.lectures {
                        for lectureUnit in lecture.lectureUnits ?? [] {

                            if let name = lectureUnit.baseUnit.name,
                               case let .attachment(attachment) = lectureUnit,
                               case let .file(file) = attachment.attachment,
                               let link = file.link,
                               let url = URL(string: link),
                               url.pathComponents.count >= 7,
                               url.lastPathComponent == id {

                                navigationController.path.append(LecturePath(id: lecture.id, coursePath: coursePath))

                                return
                            }
                        }
                    }
                }
            case let .member(login):
                Task {
                    if let conversation = await viewModel.getOneToOneChatOrCreate(login: login) {
                        navigationController.path.append(ConversationPath(conversation: conversation, coursePath: coursePath))
                    }
                }
            case let .message(id):
                guard let index = conversationViewModel.messages.firstIndex(of: .of(id: id)),
                      let messagePath = MessagePath(
                        message: Binding.constant(.done(response: conversationViewModel.messages[index].rawValue)),
                        conversationPath: ConversationPath(conversation: conversationViewModel.conversation, coursePath: coursePath),
                        conversationViewModel: conversationViewModel) else {
                    break
                }

                navigationController.path.append(messagePath)
            case let .slide(id, attachmentUnit):
                Task {
                    let vm = SendMessageLecturePickerViewModel(
                        course: conversationViewModel.course,
                        delegate: SendMessageMentionContentDelegate { _ in })

                    await vm.loadLecturesWithSlides()

                    for lecture in vm.lectures {
                        for lectureUnit in lecture.lectureUnits ?? [] where lectureUnit.baseUnit.id == attachmentUnit {

                            navigationController.path.append(LecturePath(id: lecture.id, coursePath: coursePath))

                            return
                        }
                    }
                }
            }
            return .handled
        }
        return .systemAction
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
        conversationViewModel: ConversationViewModel(
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
