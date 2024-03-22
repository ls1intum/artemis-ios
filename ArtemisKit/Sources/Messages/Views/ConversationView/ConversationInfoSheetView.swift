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

    @StateObject private var viewModel: ConversationInfoSheetViewModel

    var body: some View {
        NavigationView {
            List {
                InfoSection(viewModel: viewModel)
                membersSection
                switch viewModel.conversation {
                case .channel, .groupChat:
                    actionsSection
                default:
                    EmptyView()
                }
            }
            .task {
                await viewModel.loadMembers()
            }
            .navigationTitle(viewModel.conversation.baseConversation.conversationName)
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
            .loadingIndicator(isLoading: $viewModel.isLoading)
        }
    }
}

extension ConversationInfoSheetView {
    init(course: Course, conversation: Binding<Conversation>) {
        self.init(viewModel: ConversationInfoSheetViewModel(course: course, conversation: conversation))
    }
}

private extension ConversationInfoSheetView {
    var actionsSection: some View {
        Group {
            Section(R.string.localizable.settings()) {
                if viewModel.canAddUsers {
                    Button(R.string.localizable.addUsers()) {
                        viewModel.isAddMemberSheetPresented = true
                    }
                }
                if let channel = viewModel.conversation.baseConversation as? Channel,
                   channel.hasChannelModerationRights ?? false {
                    if channel.isArchived ?? false {
                        Button(R.string.localizable.unarchiveChannelButtonLabel()) {
                            viewModel.isLoading = true
                            Task {
                                await viewModel.unarchiveChannel()
                                viewModel.isLoading = false
                            }
                        }
                        .foregroundColor(.Artemis.badgeWarningColor)
                    } else {
                        Button(R.string.localizable.archiveChannelButtonLabel()) {
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
                    Button(R.string.localizable.leaveConversationButtonLabel()) {
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
            .sheet(isPresented: $viewModel.isAddMemberSheetPresented) {
                viewModel.isLoading = true
                Task {
                    await viewModel.refreshConversation()
                    await viewModel.loadMembers()
                    viewModel.isLoading = false
                }
            } content: {
                CreateOrAddToChatView(courseId: viewModel.course.id, configuration: .addToChat(viewModel.conversation))
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
                            HStack {
                                Text(name)
                                Spacer()
                                if UserSession.shared.user?.login == member.login {
                                    Chip(text: R.string.localizable.youLabel(), backgroundColor: .Artemis.artemisBlue)
                                }
                            }
                            .contextMenu {
                                if UserSession.shared.user?.login != member.login,
                                   viewModel.canRemoveUsers {
                                    Button(R.string.localizable.removeUserButtonLabel()) {
                                        viewModel.isLoading = true
                                        Task {
                                            await viewModel.removeMemberFromConversation(member: member)
                                            viewModel.isLoading = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } header: {
                Text(R.string.localizable.membersLabel(viewModel.conversation.baseConversation.numberOfMembers ?? 0))
            } footer: {
                pageActions
            }
        }
    }

    var pageActions: some View {
        Group {
            if (viewModel.conversation.baseConversation.numberOfMembers ?? 0) > PAGINATION_SIZE || viewModel.page > 0 {
                HStack(spacing: .l) {
                    Spacer()
                    Text("< \(R.string.localizable.previous())")
                        .onTapGesture {
                            Task {
                                await viewModel.loadPreviousMemberPage()
                            }
                        }
                        .disabled(viewModel.page == 0)
                        .foregroundColor(viewModel.page == 0 ? .Artemis.buttonDisabledColor : .Artemis.artemisBlue)
                    Text("\(viewModel.page + 1)")
                    Text("\(R.string.localizable.next()) >")
                        .onTapGesture {
                            Task {
                                await viewModel.loadNextMemberPage()
                            }
                        }
                        .disabled(
                            (viewModel.conversation.baseConversation.numberOfMembers ?? 0) <= (viewModel.page + 1) * PAGINATION_SIZE
                        )
                        .foregroundColor(
                            (viewModel.conversation.baseConversation.numberOfMembers ?? 0) <= (viewModel.page + 1) * PAGINATION_SIZE
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

    @State private var showChangeNameAlert = false
    @State private var newName = ""

    @State private var showChangeTopicAlert = false
    @State private var newTopic = ""

    @State private var showChangeDescriptionAlert = false
    @State private var newDescription = ""

    var body: some View {
        Group {
            channelSections
            if let groupChat = viewModel.conversation.baseConversation as? GroupChat {
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
            if viewModel.conversation.baseConversation.creator?.name != nil || viewModel.conversation.baseConversation.creationDate != nil {
                Section(R.string.localizable.moreInfoLabel()) {
                    if let creator = viewModel.conversation.baseConversation.creator?.name {
                        Text(R.string.localizable.createdByLabel(creator))
                    }
                    if let creationDate = viewModel.conversation.baseConversation.creationDate {
                        Text(R.string.localizable.createdOnLabel(creationDate.mediumDateShortTime))
                    }
                }
            }
        }
        .onAppear {
            newName = viewModel.conversation.baseConversation.conversationName
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
            if let channel = viewModel.conversation.baseConversation as? Channel {
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
                                Button(R.string.localizable.cancel(), role: .cancel) { 
                                    //
                                }
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
