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
                    Badge(count: unreadCount)
                }
                Menu {
                    contextMenuItems
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(.m)
                }
            }
            .opacity((conversation.unreadMessagesCount ?? 0) > 0 ? 1 : 0.7)
            .contextMenu {
                contextMenuItems
            }
        }
        .foregroundStyle((conversation.isMuted ?? false) ? .secondary : .primary)
        .listRowSeparator(.hidden)
    }
}

private extension ConversationRow {
    @ViewBuilder var contextMenuItems: some View {
        Button((conversation.isFavorite ?? false) ? R.string.localizable.unfavorite() : R.string.localizable.favorite()) {
            Task(priority: .userInitiated) {
                await viewModel.setIsConversationFavorite(conversationId: conversation.id, isFavorite: !(conversation.isFavorite ?? false))
            }
        }
        Button((conversation.isMuted ?? false) ? R.string.localizable.unmute() : R.string.localizable.mute()) {
            Task(priority: .userInitiated) {
                await viewModel.setIsConversationMuted(conversationId: conversation.id, isMuted: !(conversation.isMuted ?? false))
            }
        }
        Button((conversation.isHidden ?? false) ? R.string.localizable.show() : R.string.localizable.hide()) {
            Task(priority: .userInitiated) {
                await viewModel.setConversationIsHidden(conversationId: conversation.id, isHidden: !(conversation.isHidden ?? false))
            }
        }
    }
}
