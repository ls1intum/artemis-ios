//
//  ConversationInfoSheetView.swift
//
//
//  Created by Sven Andabaka on 23.04.23.
//

import SwiftUI
import Common
import SharedModels
import DesignLibrary
import UserStore
import Navigation

// swiftlint:disable:next identifier_name
private var PAGINATION_SIZE = 20

struct ConversationInfoSheetView: View {
    @EnvironmentObject var navigationController: NavigationController
    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel: ConversationInfoSheetViewModel

    // Triggers view update
    @Binding private var conversation: Conversation

    var body: some View {
        NavigationView {
            List {
                InfoSection(viewModel: viewModel, conversation: $conversation)
                membersSection
                switch conversation {
                case .channel, .groupChat:
                    actionsSection
                default:
                    EmptyView()
                }
            }
            .task {
                await viewModel.loadMembers()
            }
            .navigationTitle(conversation.baseConversation.conversationName)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(R.string.localizable.done()) {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
            .loadingIndicator(isLoading: $viewModel.isLoading)
            .sheet(isPresented: $viewModel.isAddMemberSheetPresented) {
                viewModel.isLoading = true
                Task {
                    await viewModel.refreshConversation()
                    await viewModel.loadMembers()
                    viewModel.isLoading = false
                }
            } content: {
                CreateOrAddToChatView(courseId: viewModel.course.id, configuration: .addToChat(conversation))
            }
        }
    }
}

extension ConversationInfoSheetView {
    init(course: Course, conversation: Binding<Conversation>) {
        self.init(viewModel: ConversationInfoSheetViewModel(course: course, conversation: conversation), conversation: conversation)
    }
}

private extension ConversationInfoSheetView {
    var actionsSection: some View {
        Section(R.string.localizable.settings()) {
            if viewModel.canAddUsers {
                Button(R.string.localizable.addUsers(), systemImage: "person.fill.badge.plus") {
                    viewModel.isAddMemberSheetPresented = true
                }
            }

            let isFavorite = conversation.baseConversation.isFavorite ?? false
            Button(isFavorite ? R.string.localizable.removeFavorite() : R.string.localizable.addFavorite(), systemImage: "heart") {
                Task {
                    await viewModel.setIsConversationFavorite(isFavorite: !isFavorite)
                }
            }
            .symbolVariant(isFavorite ? .slash.fill : .fill)
            .foregroundStyle(.orange)

            if let channel = conversation.baseConversation as? Channel,
               channel.hasChannelModerationRights ?? false {
                if channel.isArchived ?? false {
                    Button(R.string.localizable.unarchiveChannelButtonLabel(), systemImage: "archivebox.fill") {
                        viewModel.isLoading = true
                        Task {
                            await viewModel.unarchiveChannel()
                            viewModel.isLoading = false
                        }
                    }
                    .foregroundColor(.Artemis.badgeWarningColor)
                } else {
                    Button(R.string.localizable.archiveChannelButtonLabel(), systemImage: "archivebox.fill") {
                        viewModel.isLoading = true
                        Task {
                            await viewModel.archiveChannel()
                            viewModel.isLoading = false
                        }
                    }
                    .foregroundColor(.Artemis.badgeWarningColor)
                }
            }
            if viewModel.canLeaveConversation {
                Button(R.string.localizable.leaveConversationButtonLabel(), systemImage: "rectangle.portrait.and.arrow.forward") {
                    viewModel.isLoading = true
                    Task {
                        let success = await viewModel.leaveConversation()
                        if success {
                            navigationController.goToCourseConversations(courseId: viewModel.course.id)
                        } else {
                            viewModel.isLoading = false
                        }
                    }
                }
                .foregroundColor(.Artemis.badgeDangerColor)
            }
        }
    }

    private var membersSection: some View {
        Group {
            Section {
                DataStateView(data: $viewModel.members) {
                    await viewModel.loadMembers()
                } content: { members in
                    ForEach(members, id: \.id) { member in
                        if let name = member.name {
                            Menu {
                                if let login = member.login,
                                   !(conversation.baseConversation is OneToOneChat) {
                                    Button(R.string.localizable.sendMessage(), systemImage: "bubble.left.fill") {
                                        viewModel.sendMessageToUser(with: login, navigationController: navigationController) {
                                            dismiss()
                                        }
                                    }
                                }
                                Divider()
                                removeUserButton(member: member)
                            } label: {
                                HStack {
                                    Text(name)
                                    Spacer()
                                    if UserSessionFactory.shared.user?.login == member.login {
                                        Chip(text: R.string.localizable.youLabel(), backgroundColor: .Artemis.artemisBlue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                removeUserButton(member: member)
                            }
                        }
                    }
                }
            } header: {
                Text(R.string.localizable.membersLabel(conversation.baseConversation.numberOfMembers ?? 0))
            } footer: {
                pageActions
            }
        }
    }

    @ViewBuilder
    func removeUserButton(member: ConversationUser) -> some View {
        if UserSessionFactory.shared.user?.login != member.login,
           viewModel.canRemoveUsers {
            Button(R.string.localizable.removeUserButtonLabel(), systemImage: "person.badge.minus", role: .destructive) {
                viewModel.isLoading = true
                Task {
                    await viewModel.removeMemberFromConversation(member: member)
                    viewModel.isLoading = false
                }
            }
        }
    }

    var pageActions: some View {
        Group {
            if (conversation.baseConversation.numberOfMembers ?? 0) > PAGINATION_SIZE || viewModel.page > 0 {
                HStack(spacing: .l) {
                    Spacer()
                    Text("\(Image(systemName: "chevron.backward")) \(R.string.localizable.previous())")
                        .onTapGesture {
                            Task {
                                await viewModel.loadPreviousMemberPage()
                            }
                        }
                        .disabled(viewModel.page == 0)
                        .foregroundColor(viewModel.page == 0 ? .Artemis.buttonDisabledColor : .Artemis.artemisBlue)
                    Text("\(viewModel.page + 1)")
                    Text("\(R.string.localizable.next()) \(Image(systemName: "chevron.forward"))")
                        .onTapGesture {
                            Task {
                                await viewModel.loadNextMemberPage()
                            }
                        }
                        .disabled(
                            (conversation.baseConversation.numberOfMembers ?? 0) <= (viewModel.page + 1) * PAGINATION_SIZE
                        )
                        .foregroundColor(
                            (conversation.baseConversation.numberOfMembers ?? 0) <= (viewModel.page + 1) * PAGINATION_SIZE
                                ? .Artemis.buttonDisabledColor
                                : .Artemis.artemisBlue
                        )
                    Spacer()
                }.font(.body)
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - InfoSection

private struct InfoSection: View {
    @ObservedObject var viewModel: ConversationInfoSheetViewModel

    // Triggers view update
    @Binding var conversation: Conversation

    @State private var showChangeNameAlert = false
    @State private var newName = ""

    @State private var showChangeTopicAlert = false
    @State private var newTopic = ""

    @State private var showChangeDescriptionAlert = false
    @State private var newDescription = ""

    var body: some View {
        Group {
            channelSections
            if let groupChat = conversation.baseConversation as? GroupChat {
                Section(R.string.localizable.nameLabel()) {
                    HStack {
                        Text(groupChat.name ?? R.string.localizable.noNameSet())
                        if groupChat.isMember ?? false {
                            Spacer()
                            Button(action: { showChangeNameAlert = true }, label: {
                                Image(systemName: "pencil")
                            })
                        }
                    }
                }
            }
            if conversation.baseConversation.creator?.name != nil || conversation.baseConversation.creationDate != nil {
                Section(R.string.localizable.moreInfoLabel()) {
                    if let creator = conversation.baseConversation.creator?.name {
                        Text(R.string.localizable.createdByLabel(creator))
                    }
                    if let creationDate = conversation.baseConversation.creationDate {
                        Text(R.string.localizable.createdOnLabel(creationDate.mediumDateShortTime))
                    }
                }
            }
        }
        .onAppear {
            newName = conversation.baseConversation.conversationName
        }
        .alert(R.string.localizable.editNameTitle(), isPresented: $showChangeNameAlert) {
            TextField(R.string.localizable.newNameLabel(), text: $newName)
            Button(R.string.localizable.ok()) {
                viewModel.isLoading = true
                Task {
                    await viewModel.editName(newName: newName)
                }
            }
            Button(R.string.localizable.cancel(), role: .cancel) { }
        }
        .textCase(nil)
    }
}

private extension InfoSection {
    var channelSections: some View {
        Group {
            if let channel = conversation.baseConversation as? Channel {
                Section(R.string.localizable.nameLabel()) {
                    HStack {
                        Text(channel.name ?? R.string.localizable.noNameSet())
                        if channel.hasChannelModerationRights ?? false {
                            Spacer()
                            Button {
                                showChangeNameAlert = true
                            } label: {
                                Image(systemName: "pencil")
                            }
                        }
                    }
                }
                Section(R.string.localizable.topicLabel()) {
                    HStack {
                        Text(channel.topic ?? R.string.localizable.noTopicSet())
                        if channel.hasChannelModerationRights ?? false {
                            Spacer()
                            Button {
                                showChangeTopicAlert = true
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .alert(R.string.localizable.editTopicTitle(), isPresented: $showChangeTopicAlert) {
                                TextField(R.string.localizable.newTopicLabel(), text: $newTopic)
                                Button(R.string.localizable.ok()) {
                                    viewModel.isLoading = true
                                    Task {
                                        await viewModel.editTopic(newTopic: newTopic)
                                    }
                                }
                                Button(R.string.localizable.cancel(), role: .cancel) { }
                            }
                            .textCase(nil)
                        }
                    }
                }
                Section(R.string.localizable.description()) {
                    HStack {
                        Text(channel.description ?? R.string.localizable.noDescriptionSet())
                        if channel.hasChannelModerationRights ?? false {
                            Spacer()
                            Button {
                                showChangeDescriptionAlert = true
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .alert(R.string.localizable.editDescriptionLabel(), isPresented: $showChangeDescriptionAlert) {
                                TextField(R.string.localizable.newDescriptionLabel(), text: $newDescription)
                                Button(R.string.localizable.ok()) {
                                    viewModel.isLoading = true
                                    Task {
                                        await viewModel.editDescription(newDescription: newDescription)
                                    }
                                }
                                Button(R.string.localizable.cancel(), role: .cancel) {}
                            }
                            .textCase(nil)
                        }
                    }
                }
                .onAppear {
                    newTopic = channel.topic ?? ""
                    newDescription = channel.description ?? ""
                }
            }
        }
    }
}
