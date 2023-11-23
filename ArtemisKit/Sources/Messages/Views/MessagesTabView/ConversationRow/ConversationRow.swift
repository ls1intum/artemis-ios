//
//  ConversationRow.swift
//
//
//  Created by Nityananda Zbil on 10.11.23.
//

import Navigation
import SharedModels
import SwiftUI

struct ConversationRow<T: BaseConversation>: View {

    @EnvironmentObject var navigationController: NavigationController

    @ObservedObject var viewModel: MessagesAvailableViewModel

    let conversation: T

    var body: some View {
        Button {
            // should always be non-optional
            if let conversation = Conversation(conversation: conversation) {
                navigationController.path.append(ConversationPath(conversation: conversation, coursePath: CoursePath(course: viewModel.course)))
            }
        } label: {
            HStack {
                if let icon = conversation.icon {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: .extraSmallImage, height: .extraSmallImage)
                }
                Text(conversation.conversationName)
                Spacer()
                if let unreadCount = conversation.unreadMessagesCount {
                    Badge(unreadCount: unreadCount)
                }
            }
            .opacity((conversation.unreadMessagesCount ?? 0) > 0 ? 1 : 0.7)
            .contextMenu {
                contextMenuItems
            }
        }
        .foregroundStyle(foregroundStyle)
        .listRowSeparator(.hidden)
    }

    var contextMenuItems: some View {
        Group {
            Button((conversation.isHidden ?? false) ? R.string.localizable.show() : R.string.localizable.hide()) {
                Task(priority: .userInitiated) {
                    await viewModel.hideUnhideConversation(conversationId: conversation.id, isHidden: !(conversation.isHidden ?? false))
                }
            }
            Button((conversation.isFavorite ?? false) ? R.string.localizable.unfavorite() : R.string.localizable.favorite()) {
                Task(priority: .userInitiated) {
                    await viewModel.setIsFavoriteConversation(conversationId: conversation.id, isFavorite: !(conversation.isFavorite ?? false))
                }
            }
            Button(muteButtonLabel) {
                Task(priority: .userInitiated) {
                    switch conversation.muted {
                    case .muted:
                        await viewModel.setMutedConversation(conversationId: conversation.id, muted: .unmuted)
                    case .unmuted:
                        await viewModel.setMutedConversation(conversationId: conversation.id, muted: .muted)
                    case nil:
                        await viewModel.setMutedConversation(conversationId: conversation.id, muted: .muted)
                    }
                }
            }
        }
    }
}

private extension ConversationRow {
    var muteButtonLabel: String {
        switch conversation.muted ?? .unmuted {
        case .muted:
            "Unmute"
        case .unmuted:
            "Mute"
        }
    }

    var foregroundStyle: Color {
        switch conversation.muted ?? .unmuted {
        case .muted:
            Color.gray
        case .unmuted:
            Color.black
        }
    }
}
