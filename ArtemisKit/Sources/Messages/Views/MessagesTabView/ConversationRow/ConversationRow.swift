//
//  ConversationRow.swift
//
//
//  Created by Nityananda Zbil on 10.11.23.
//

import Navigation
import SharedModels
import SwiftUI

struct ConversationRow: View {

    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var navigationController: NavigationController

    @ObservedObject var viewModel: MessagesAvailableViewModel

    let conversation: BaseConversation
    var namePrefix: String?

    var body: some View {
        // should always be non-optional
        if let conversationForPath = Conversation(conversation: conversation) {
            NavigationLink(value: ConversationPath(conversation: conversationForPath, coursePath: CoursePath(course: viewModel.course))) {
                HStack {
                    ConversationRowLabel(conversation: conversation, namePrefix: namePrefix)
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
            .tag(ConversationPath(conversation: conversationForPath, coursePath: CoursePath(course: viewModel.course)))
            .foregroundStyle((conversation.isMuted ?? false) ? .secondary : .primary)
            .listRowInsets(EdgeInsets(top: 0,
                                      leading: .s * -1,
                                      bottom: 0,
                                      // We need to move the chevron off screen if it exists
                                      trailing: .m * (sizeClass == .compact ? -1 : 1)))
            .swipeActions(edge: .leading) {
                favoriteButton
            }
            .swipeActions(edge: .trailing) {
                hideAndMuteButtons
            }
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
        Button(isHidden ? R.string.localizable.unarchive() : R.string.localizable.archive(),
               systemImage: "archivebox.fill") {
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

struct ConversationRowLabel: View {
    @Environment(\.showFavoriteIcon) var showFavoriteIcon

    let conversation: BaseConversation
    var namePrefix: String?

    var conversationDisplayName: String {
        let conversationName = conversation.conversationName
        guard let namePrefix, !namePrefix.isEmpty else {
            return conversationName
        }
        if conversationName.hasPrefix(namePrefix) {
            return String(conversationName.suffix(conversationName.count - namePrefix.count))
        }
        return conversationName
    }

    var body: some View {
        Label {
            HStack(alignment: .firstTextBaseline) {
                Text(conversationDisplayName)
                    .fontWeight(conversation.unreadMessagesCount ?? 0 > 0 ? .semibold : .regular)
                Spacer()
                if let unreadCount = conversation.unreadMessagesCount, unreadCount > 0 {
                    Text(unreadCount, format: .number.notation(.compactName))
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(.vertical, .s)
                        .padding(.horizontal, .m)
                        .background(Color.Artemis.artemisBlue, in: .capsule)
                }
            }
        } icon: {
            conversationIcon
        }
    }

    @ViewBuilder var conversationIcon: some View {
        if let icon = conversation.icon {
            icon
                .scaledToFit()
                .frame(height: .extraSmallImage)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .overlay(alignment: .topTrailing) {
                    if let unreadCount = conversation.unreadMessagesCount, unreadCount > 0 {
                        Circle()
                            .stroke(.background, lineWidth: .xs)
                            .fill(Color.Artemis.artemisBlue)
                            .frame(width: .m, height: .m)
                            .offset(x: .s, y: .xs * -1)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if conversation.isFavorite ?? false && showFavoriteIcon {
                        Image(systemName: "heart.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.orange)
                            .frame(width: .m, height: .m)
                            .offset(x: .s, y: .s)
                    }
                }
        }
    }
}

// MARK: Environment Values

private enum ConversationRowFavoriteIconKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var showFavoriteIcon: Bool {
        get {
            self[ConversationRowFavoriteIconKey.self]
        }
        set {
            self[ConversationRowFavoriteIconKey.self] = newValue
        }
    }
}
