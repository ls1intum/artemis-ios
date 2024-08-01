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
                Label {
                    HStack(alignment: .firstTextBaseline) {
                        Text(conversation.conversationName)
                        if let unreadCount = conversation.unreadMessagesCount, unreadCount > 0 {
                            Text(R.string.localizable.unread(unreadCount))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    if let icon = conversation.icon {
                        icon
                            .resizable()
                            .scaledToFit()
                            .frame(height: .extraSmallImage)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .overlay(alignment: .bottomTrailing) {
                                if let unreadCount = conversation.unreadMessagesCount, unreadCount > 0 {
                                    Circle()
                                        .stroke(.background, lineWidth: .xs)
                                        .fill(Color.Artemis.artemisBlue)
                                        .frame(width: .m, height: .m)
                                        .offset(x: .xs, y: .xs)
                                }
                            }
                    }
                }
                Spacer()
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
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: .m))
        .swipeActions(edge: .leading) {
            favoriteButton
        }
        .swipeActions(edge: .trailing) {
            hideAndMuteButtons
        }
    }
}

private extension ConversationRow {
    @ViewBuilder var favoriteButton: some View {
        let isFavorite = conversation.isFavorite ?? false
        Button(isFavorite ? R.string.localizable.unfavorite() : R.string.localizable.favorite(),
               systemImage: isFavorite ? "heart.slash.fill" : "heart.fill") {
            Task(priority: .userInitiated) {
                await viewModel.setIsConversationFavorite(conversationId: conversation.id, isFavorite: !(conversation.isFavorite ?? false))
            }
        }.tint(.orange)
    }

    @ViewBuilder var hideAndMuteButtons: some View {
        let isHidden = conversation.isHidden ?? false
        Button(isHidden ? R.string.localizable.show() : R.string.localizable.hide(),
               systemImage: isHidden ? "eye.fill" : "eye.slash.fill") {
            Task(priority: .userInitiated) {
                await viewModel.setConversationIsHidden(conversationId: conversation.id, isHidden: !(conversation.isHidden ?? false))
            }
        }.tint(.gray)

        let isMuted = conversation.isMuted ?? false
        Button(isMuted ? R.string.localizable.unmute() : R.string.localizable.mute(),
               systemImage: isMuted ? "bell.fill" : "bell.slash.fill") {
            Task(priority: .userInitiated) {
                await viewModel.setIsConversationMuted(conversationId: conversation.id, isMuted: !(conversation.isMuted ?? false))
            }
        }.tint(.indigo)
    }

    @ViewBuilder var contextMenuItems: some View {
        favoriteButton
        hideAndMuteButtons
    }
}
