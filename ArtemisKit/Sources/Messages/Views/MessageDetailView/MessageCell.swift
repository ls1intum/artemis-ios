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
    @Environment(\.messageUseFullWidth) var useFullWidth: Bool
    @EnvironmentObject var navigationController: NavigationController

    @ObservedObject var conversationViewModel: ConversationViewModel

    @Binding var message: DataState<BaseMessage>

    @State var viewModel: MessageCellModel

    var body: some View {
        VStack(alignment: .leading, spacing: .s) {
            HStack {
                VStack(alignment: .leading, spacing: .s) {
                    pinnedIndicator
                    resolvesPostIndicator
                    headerIfVisible
                    ArtemisMarkdownView(string: content)
                        .opacity(isMessageOffline ? 0.5 : 1)
                        .environment(\.openURL, OpenURLAction(handler: handle))
                    editedLabel
                    resolvedIndicator
                }
                Spacer()
            }
            .background(backgroundOnPress, in: .rect(cornerRadius: .m))
            .contentShape(.rect)
            .onTapGesture(perform: onTapPresentMessage)
            .onLongPressGesture(perform: onLongPressPresentActionSheet) { changed in
                viewModel.isDetectingLongPress = changed
            }

            ReactionsView(viewModel: conversationViewModel, message: $message)
            retryButtonIfAvailable
            replyButtonIfAvailable
        }
        .padding(.horizontal, .m)
        .padding(viewModel.isHeaderVisible ? .vertical : .bottom, useFullWidth ? 0 : .m)
        .contentShape(.rect)
        .gesture(viewModel.swipeToReplyGesture(openThread: onSwipePresentMessage))
        .blur(radius: viewModel.swipeToReplyState.messageBlur)
        .overlay(alignment: .trailing) {
            swipeToReplyOverlay
        }
        .background(
            useFullWidth ?
                .clear :
                isPinned ? .orange.opacity(0.25) :
                resolvesPost ? .green.opacity(0.2) : Color(uiColor: .secondarySystemBackground),
            in: .rect(cornerRadii: viewModel.roundedCorners)
        )
        .padding(.top, viewModel.isHeaderVisible ? .m : 0)
        .id(message.value?.id.description)
        .padding(.horizontal, useFullWidth ? 0 : (.m + .l) / 2)
        .onDisappear(perform: viewModel.resetSwipeToReply)
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
        roundBottomCorners: Bool,
        retryButtonAction: (() -> Void)? = nil
    ) {
        self.init(
            conversationViewModel: conversationViewModel,
            message: message,
            viewModel: MessageCellModel(
                course: conversationViewModel.course,
                conversationPath: conversationPath,
                isHeaderVisible: isHeaderVisible,
                roundBottomCorners: roundBottomCorners,
                retryButtonAction: retryButtonAction)
        )
    }
}

private extension MessageCell {
    var author: String {
        message.value?.author?.name ?? ""
    }

    private var authorRole: UserRole? {
        message.value?.authorRole
    }

    var creationDate: Date? {
        message.value?.creationDate
    }

    var content: String {
        message.value?.content ?? ""
    }

    var isPinned: Bool {
        (message.value as? Message)?.displayPriority == .pinned
    }

    var isResolved: Bool {
        (message.value as? Message)?.resolved ?? false ||
        (message.value as? Message)?.answers?.contains { answer in
            answer.resolvesPost ?? false
        } ?? false
    }

    var resolvesPost: Bool {
        (message.value as? AnswerMessage)?.resolvesPost ?? false
    }

    var backgroundOnPress: Color {
        (viewModel.isDetectingLongPress || viewModel.isActionSheetPresented) ? Color.primary.opacity(0.1) : Color.clear
    }

    @ViewBuilder var roleBadge: some View {
        if let authorRole {
            Chip(
                text: authorRole.displayName,
                backgroundColor: authorRole.badgeColor,
                horizontalPadding: .m,
                verticalPadding: .s
            )
            .font(.footnote)
        }
    }

    @ViewBuilder var pinnedIndicator: some View {
        if isPinned {
            Label(R.string.localizable.pinned(), systemImage: "pin")
                .font(.caption)
        }
    }

    @ViewBuilder var resolvedIndicator: some View {
        if isResolved && viewModel.conversationPath != nil {
            Label(R.string.localizable.resolved(), systemImage: "checkmark")
                .font(.caption)
        }
    }

    @ViewBuilder var resolvesPostIndicator: some View {
        if resolvesPost {
            Label(R.string.localizable.resolvesPost(), systemImage: "checkmark")
                .font(.caption)
        }
    }

    @ViewBuilder var headerIfVisible: some View {
        if viewModel.isHeaderVisible {
            HStack(alignment: .firstTextBaseline, spacing: .m) {
                roleBadge
                Text(isMessageOffline ? "Redacted" : author)
                    .bold()
                    .redacted(reason: isMessageOffline ? .placeholder : [])
                if let creationDate {
                    let formatter: DateFormatter = viewModel.conversationPath == nil ? .superShortDateAndTime : .timeOnly
                    Text(creationDate, formatter: formatter)
                        .font(.caption)
                    if viewModel.isChipVisible(creationDate: creationDate, authorId: message.value?.author?.id) {
                        Chip(
                            text: R.string.localizable.new(),
                            backgroundColor: .Artemis.artemisBlue,
                            padding: .s
                        )
                        .font(.footnote)
                    }
                }
            }
        }
    }

    @ViewBuilder var editedLabel: some View {
        if let updatedDate = message.value?.updatedDate {
            Group {
                Text(R.string.localizable.edited() + " (") +
                Text(updatedDate, formatter: DateFormatter.superShortDateAndTime) +
                Text(")")
            }
            .font(.caption)
            .foregroundColor(.Artemis.secondaryLabel)
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
           viewModel.conversationPath != nil {
            Button {
                openThread(showErrorOnFailure: true)
            } label: {
                Label {
                    Text("^[\(answerCount) \(R.string.localizable.reply())](inflect: true)")
                } icon: {
                    Image(systemName: "arrow.turn.down.right")
                }
            }
        }
    }

    @ViewBuilder var swipeToReplyOverlay: some View {
        Image(systemName: "arrowshape.turn.up.left.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 40)
            .foregroundStyle(viewModel.swipeToReplyState.swiped ? .blue : .gray)
            .padding(.horizontal)
            .offset(x: viewModel.swipeToReplyState.overlayOffset)
            .scaleEffect(x: viewModel.swipeToReplyState.overlayScale, y: viewModel.swipeToReplyState.overlayScale, anchor: .trailing)
            .opacity(viewModel.swipeToReplyState.overlayOpacity)
            .animation(.easeInOut(duration: 0.1), value: viewModel.swipeToReplyState.swiped)
            .accessibilityHidden(true)
    }

    func openThread(showErrorOnFailure: Bool = true, presentKeyboard: Bool = false) {
        // We cannot navigate to details if conversation path is nil, e.g. in the message detail view.
        if let conversationPath = viewModel.conversationPath,
           let messagePath = MessagePath(
            message: $message,
            conversationPath: conversationPath,
            conversationViewModel: conversationViewModel,
            presentKeyboardOnAppear: presentKeyboard
        ) {
            navigationController.path.append(messagePath)
        } else if showErrorOnFailure {
            conversationViewModel.presentError(userFacingError: UserFacingError(title: R.string.localizable.detailViewCantBeOpened()))
        }
    }

    // MARK: Gestures

    func onTapPresentMessage() {
        openThread(showErrorOnFailure: false)
    }

    func onSwipePresentMessage() {
        openThread(presentKeyboard: true)
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
                    let delegate = SendMessageLecturePickerViewModel(course: conversationViewModel.course)

                    await delegate.loadLecturesWithSlides()

                    if let lecture = delegate.firstLectureContains(attachmentUnit: attachmentUnit) {
                        navigationController.path.append(LecturePath(id: lecture.id, coursePath: coursePath))
                        return
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
            case let .slide(number, attachmentUnit):
                Task {
                    let delegate = SendMessageLecturePickerViewModel(course: conversationViewModel.course)

                    await delegate.loadLecturesWithSlides()

                    if let lecture = delegate.firstLectureContains(attachmentUnit: attachmentUnit) {
                        navigationController.path.append(LecturePath(id: lecture.id, coursePath: coursePath))
                        return
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
private enum MessageFullWidthEnvironmentKey: EnvironmentKey {
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
    var messageUseFullWidth: Bool {
        get {
            self[MessageFullWidthEnvironmentKey.self]
        }
        set {
            self[MessageFullWidthEnvironmentKey.self] = newValue
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
        isHeaderVisible: true,
        roundBottomCorners: true
    )
}
