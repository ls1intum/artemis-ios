//
//  MessageCellModel.swift
//
//
//  Created by Nityananda Zbil on 25.03.24.
//

import Foundation
import Navigation
import SharedModels
import SwiftUI
import UserStore

@MainActor
@Observable
final class MessageCellModel {
    let course: Course

    let conversationPath: ConversationPath?
    let isHeaderVisible: Bool
    let roundBottomCorners: Bool
    let retryButtonAction: (() -> Void)?

    var isActionSheetPresented = false
    var isDetectingLongPress = false

    private let messagesService: MessagesService
    private let userSession: UserSession

    init(
        course: Course,
        conversationPath: ConversationPath?,
        isHeaderVisible: Bool,
        roundBottomCorners: Bool,
        retryButtonAction: (() -> Void)?,
        messagesService: MessagesService = MessagesServiceFactory.shared,
        userSession: UserSession = UserSessionFactory.shared
    ) {
        self.course = course
        self.conversationPath = conversationPath
        self.isHeaderVisible = isHeaderVisible
        self.roundBottomCorners = roundBottomCorners
        self.retryButtonAction = retryButtonAction
        self.messagesService = messagesService
        self.userSession = userSession
    }

    // View properties for Swipe to reply
    var swipedToReply = false
    var swipeToReplyOverlayOffset: CGFloat = 100
    var swipeBlur: CGFloat = 0
    var swipeOpacity: CGFloat = 0
    var swipeScale: CGFloat = 0
}

extension MessageCellModel {
    // MARK: View

    func isChipVisible(creationDate: Date, authorId: Int64?) -> Bool {
        guard let lastReadDate = conversationPath?.conversation?.baseConversation.lastReadDate else {
            return false
        }

        return lastReadDate < creationDate && userSession.user?.id != authorId
    }

    var roundedCorners: RectangleCornerRadii {
        let top: CGFloat = isHeaderVisible ? .m : 0
        let bottom: CGFloat = roundBottomCorners ? .m : 0
        return .init(topLeading: top, bottomLeading: bottom, bottomTrailing: bottom, topTrailing: top)
    }

    func swipeToReplyGesture(openThread: @escaping () -> Void) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // No swiping in Thread View
                guard self.conversationPath != nil else { return }

                // Only allow swipe to the left
                let distance = min(value.translation.width, 0)

                self.swipeToReplyOverlayOffset = 200 * exp((distance - 10) / 30)
                self.swipeBlur = max((-distance - 25) * 0.25, 0)
                self.swipeOpacity = max(0, min(-(distance + 40) * 0.05, 1))
                self.swipeScale = max(0, min(-(distance + 40) * 0.03, 1))

                // If user had dragged far enough to activate reply, let them know
                if !self.swipedToReply && distance < -70 {
                    self.swipedToReply = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } else if self.swipedToReply && distance >= -70 {
                    self.swipedToReply = false
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
            .onEnded { _ in
                if self.swipedToReply {
                    openThread()
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.resetSwipeToReply()
                    }
                }
            }
    }

    func resetSwipeToReply() {
        self.swipedToReply = false
        self.swipeOpacity = 0
        self.swipeBlur = 0
        self.swipeToReplyOverlayOffset = 100
        self.swipeScale = 0
    }

    // MARK: Navigation

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
