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

    var showReactionsPopover = false
    var isDetectingLongPress = false

    var presentingAttachmentURL: URL?

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
}

extension MessageCellModel {
    // MARK: View

    func isChipVisible(creationDate: Date, authorId: Int64?) -> Bool {
        guard let lastReadDate = conversationPath?.conversation?.baseConversation.lastReadDate else {
            return false
        }

        return lastReadDate < creationDate && userSession.user?.id != authorId
    }

    func roundedCorners(isSelected: Bool) -> RectangleCornerRadii {
        let top: CGFloat = isHeaderVisible || isSelected ? .m : 0
        let bottom: CGFloat = roundBottomCorners || isSelected ? .m : 0
        return .init(topLeading: top, bottomLeading: bottom, bottomTrailing: bottom, topTrailing: top)
    }

    // MARK: Navigation

    func getOneToOneChatOrCreate(login: String? = nil, userId: Int? = nil) async -> Conversation? {
        guard login != nil || userId != nil else { return nil }
        async let conversations = messagesService.getConversations(for: course.id)
        async let chat = if login != nil {
            messagesService.createOneToOneChat(for: course.id, usernames: [login ?? ""])
        } else {
            messagesService.createOneToOneChat(for: course.id, userId: userId ?? -1)
        }

        if let conversations = await conversations.value,
           let conversation = conversations.first(where: { conversation in
               guard case let .oneToOneChat(conversation) = conversation,
                     let members = conversation.members else {
                   return false
               }
               return members.contains(where: {
                   $0.id == userId ?? -1 || ($0.login == login && login != nil)
               })
           }) {
            return conversation
        } else if let chat = await chat.value {
            return Conversation.oneToOneChat(conversation: chat)
        }

        return nil
    }
}

// MARK: Swipe to Reply
@Observable
class SwipeToReplyState {
    var swiped = false
    var overlayOffset: CGFloat = 100
    var overlayOpacity: CGFloat = 0
    var overlayScale: CGFloat = 0
    var messageBlur: CGFloat = 0

    // Configurable properties
    private let blurIntensity: CGFloat = 0.75

    /// Update all view properies associated with swiping to reply
    func update(with distance: CGFloat) {
        overlayOffset = 200 * exp((distance - 15) / 30)
        messageBlur = max((-distance - 30) * 0.2 * blurIntensity, 0)
        overlayOpacity = max(0, min(-(distance + 35) * 0.05, 1))
        overlayScale = max(0, min(-(distance + 35) * 0.03, 1))

        // If user dragged far enough to activate reply, let them know
        if !swiped && distance < -70 {
            swiped = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else if swiped && distance >= -70 {
            swiped = false
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    /// Sets all values back to default
    func reset() {
        swiped = false
        overlayOffset = 100
        overlayOpacity = 0
        overlayScale = 0
        messageBlur = 0
    }
}
