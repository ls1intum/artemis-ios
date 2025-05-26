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
import Faq

struct MessageCell: View {
    @Environment(\.isMessageOffline) var isMessageOffline: Bool
    @Environment(\.messageUseFullWidth) var useFullWidth: Bool
    @EnvironmentObject var navigationController: NavigationController

    @ObservedObject var conversationViewModel: ConversationViewModel

    @Binding var message: DataState<BaseMessage>

    @State var viewModel: MessageCellModel

    var body: some View {
        VStack(alignment: .leading, spacing: .s) {
            reactionMenuIfAvailable

            VStack(alignment: .leading, spacing: .s) {
                savedIndicator
                pinnedIndicator
                resolvesPostIndicator
                headerIfVisible
                if !title.isEmpty {
                    Text(title)
                        .fontWeight(.bold)
                }
                ArtemisMarkdownView(string: content.surroundingMarkdownImagesWithNewlines())
                    .opacity(isMessageOffline ? 0.5 : 1)
                    .messageUrlHandler(conversationViewModel: conversationViewModel,
                                       cellViewModel: viewModel)
                    .environment(\.imagePreviewsEnabled, viewModel.conversationPath == nil)
                editedLabel
                resolvedIndicator
                ForwardedMessageView(viewModel: conversationViewModel,
                                     message: message.value as? Message)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture(perform: onTapPresentMessage)
            .onLongPressGesture(perform: onLongPressPresentActionSheet) { changed in
                viewModel.isDetectingLongPress = changed
            }

            ReactionsView(viewModel: conversationViewModel, message: $message)
            retryButtonIfAvailable
            replyButtonIfAvailable

            actionsMenuIfAvailable
        }
        .padding(.horizontal, .m)
        .padding(viewModel.isHeaderVisible ? .vertical : .bottom, useFullWidth ? 0 : .m)
        .contentShape(.rect)
        .modifier(SwipeToReply(enabled: viewModel.conversationPath != nil, onSwipe: onSwipePresentMessage))
        .background(backgroundOnPress, in: .rect(cornerRadius: .m))
        .background(messageBackground,
                    in: .rect(cornerRadii: viewModel.roundedCorners(isSelected: isSelected)))
        .padding(.top, viewModel.isHeaderVisible ? .m : 0)
        .padding(.horizontal, useFullWidth ? 0 : .m)
        .opacity(opacity)
        .id(message.value?.id.description)
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
        authorUser?.name ?? ""
    }

    private var authorRole: UserRole? {
        message.value?.authorRole
    }

    private var authorUser: ConversationUser? {
        return message.value?.author
    }

    var creationDate: Date? {
        message.value?.creationDate
    }

    var content: String {
        message.value?.content ?? ""
    }

    var title: String {
        (message.value as? Message)?.title ?? ""
    }

    var isSaved: Bool {
        message.value?.isBookmarked ?? false
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

    var isSelected: Bool {
        guard let selectedId = conversationViewModel.selectedMessageId else { return false }
        return selectedId == message.value?.id
    }

    var opacity: CGFloat {
        guard conversationViewModel.selectedMessageId != nil else { return 1 }
        return isSelected ? 1 : 0.25
    }

    var backgroundOnPress: Color {
        viewModel.isDetectingLongPress ? Color.primary.opacity(0.1) : Color.clear
    }

    var messageBackground: Color {
        useFullWidth ? .clear :
        isSaved ? .blue.opacity(0.2) :
        isPinned ? .orange.opacity(0.25) :
        resolvesPost ? .green.opacity(0.2) :
        .clear
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

    @ViewBuilder var savedIndicator: some View {
        if isSaved {
            Label(R.string.localizable.savedMessage(), systemImage: "bookmark")
                .font(.caption)
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
            HStack(alignment: .top, spacing: .m) {
                if let authorUser {
                    ProfilePictureView(user: authorUser, role: authorRole, course: viewModel.course)
                }
                VStack(alignment: .leading, spacing: .xs) {
                    HStack(alignment: .firstTextBaseline, spacing: .m) {
                        roleBadge
                        Spacer()
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
                    Text(isMessageOffline ? "Redacted" : author)
                        .bold()
                        .redacted(reason: isMessageOffline ? .placeholder : [])
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
           viewModel.conversationPath != nil, !isSelected {
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

    @ViewBuilder var actionsMenuIfAvailable: some View {
        if isSelected && !useFullWidth {
            MessageActionsMenu(viewModel: conversationViewModel,
                               message: $message,
                               conversationPath: viewModel.conversationPath)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 5)
            .transition(.scale(0, anchor: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder var reactionMenuIfAvailable: some View {
        if isSelected {
            MessageReactionsPopover(viewModel: conversationViewModel,
                                    message: $message,
                                    conversationPath: viewModel.conversationPath)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 5)
            .transition(.scale(0, anchor: .bottom).combined(with: .opacity))
        }
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
            navigationController.tabPath.append(messagePath)
        } else if showErrorOnFailure {
            conversationViewModel.presentError(userFacingError: UserFacingError(title: R.string.localizable.detailViewCantBeOpened()))
        }
    }

    // MARK: Gestures

    func onTapPresentMessage() {
        if conversationViewModel.selectedMessageId == nil || isSelected {
            openThread(showErrorOnFailure: false)
        }
        conversationViewModel.selectedMessageId = nil
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
        withAnimation {
            conversationViewModel.selectedMessageId = message.value?.id
        }
        viewModel.isDetectingLongPress = false
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
