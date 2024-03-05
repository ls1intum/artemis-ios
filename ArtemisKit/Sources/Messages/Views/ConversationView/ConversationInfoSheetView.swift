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

    @StateObject private var viewModel = ConversationInfoSheetViewModel()

    @Binding var conversation: DataState<Conversation>
    var course: Course
    var conversationId: Int64

    @State private var showAddMemberSheet = false

    var body: some View {
        NavigationView {
            DataStateView(data: $conversation) {
                #warning("Mutation")
                self.conversation = await viewModel.reloadConversation(for: course.id, conversationId: conversationId)
            } content: { conversation in
                List {
                    InfoSection(viewModel: viewModel, conversation: $conversation, course: course)
                    membersSection
                    switch conversation {
                    case .channel, .groupChat:
                        actionsSection
                    default:
                        EmptyView()
                    }
                }
                .task {
                    await viewModel.loadMembers(for: course.id, conversationId: conversation.id)
                }
                .navigationTitle(conversation.baseConversation.conversationName)
                .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
                .loadingIndicator(isLoading: $viewModel.isLoading)
            }
        }
    }
}

private extension ConversationInfoSheetView {
    var canLeaveConversation: Bool {
        guard let conversation = conversation.value else {
            return false
        }
        // not possible to leave a conversation as not a member
        if !(conversation.baseConversation.isMember ?? false) {
            return false
        }
        // the creator of a channel can not leave it
        if conversation.baseConversation is Channel && conversation.baseConversation.isCreator ?? false {
            return false
        }
        // can not leave a oneToOne chat
        if conversation.baseConversation is OneToOneChat {
            return false
        }
        return true
    }

    var canAddUsers: Bool {
        guard let conversation = conversation.value else {
            return false
        }
        switch conversation {
        case .channel(let conversation):
            return conversation.hasChannelModerationRights ?? false
        case .groupChat(let conversation):
            return conversation.isMember ?? false
        case .oneToOneChat:
            return false
        case .unknown:
            return false
        }
    }

    var canRemoveUsers: Bool {
        canAddUsers
    }

    // MARK: View

    var actionsSection: some View {
        Group {
            if let conversation = conversation.value {
                Section(R.string.localizable.settings()) {
                    if canAddUsers {
                        Button(R.string.localizable.addUsers()) {
                            showAddMemberSheet = true
                        }
                    }
                    if let channel = conversation.baseConversation as? Channel,
                       channel.hasChannelModerationRights ?? false {
                        if channel.isArchived ?? false {
                            Button(R.string.localizable.unarchiveChannelButtonLabel()) {
                                viewModel.isLoading = true
                                Task(priority: .userInitiated) {
                                    let result = await viewModel.unarchiveChannel(for: course.id, conversationId: conversation.id)
                                    switch result {
                                    case .loading, .failure:
                                        // do nothing
                                        break
                                    case .done:
                                        #warning("Mutation")
                                        self.conversation = result
                                    }
                                    viewModel.isLoading = false
                                }
                            }
                            .foregroundColor(.Artemis.badgeWarningColor)
                        } else {
                            Button(R.string.localizable.archiveChannelButtonLabel()) {
                                viewModel.isLoading = true
                                Task(priority: .userInitiated) {
                                    let result = await viewModel.archiveChannel(for: course.id, conversationId: conversation.id)
                                    switch result {
                                    case .loading, .failure:
                                        // do nothing
                                        break
                                    case .done:
                                        #warning("Mutation")
                                        self.conversation = result
                                    }
                                    viewModel.isLoading = false
                                }
                            }
                            .foregroundColor(.Artemis.badgeWarningColor)
                        }
                    }
                    if canLeaveConversation {
                        Button(R.string.localizable.leaveConversationButtonLabel()) {
                            viewModel.isLoading = true
                            Task(priority: .userInitiated) {
                                let success = await viewModel.leaveConversation(for: course.id, conversation: conversation)
                                if success {
                                    navigationController.goToCourseConversations(courseId: course.id)
                                } else {
                                    viewModel.isLoading = false
                                }
                            }
                        }
                        .foregroundColor(.Artemis.badgeDangerColor)
                    }
                }
                .sheet(isPresented: $showAddMemberSheet) {
                    viewModel.isLoading = true
                    Task {
                        let result = await viewModel.reloadConversation(for: course.id, conversationId: conversation.id)
                        switch result {
                        case .loading, .failure:
                            // do nothing
                            break
                        case .done:
                            #warning("Mutation")
                            self.conversation = result
                        }
                        await viewModel.loadMembers(for: course.id, conversationId: conversation.id)
                        viewModel.isLoading = false
                    }
                } content: {
                    CreateOrAddToChatView(courseId: course.id, type: .addToChat(conversation))
                }
            }
        }
    }

    private var membersSection: some View {
        Group {
            if let conversation = conversation.value {
                Section(content: {
                    DataStateView(data: $viewModel.members) {
                        await viewModel.loadMembers(for: course.id, conversationId: conversation.id)
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
                                       canRemoveUsers {
                                        Button(R.string.localizable.removeUserButtonLabel()) {
                                            viewModel.isLoading = true
                                            Task(priority: .userInitiated) {
                                                let result = await viewModel.removeMemberFromConversation(for: course.id, conversation: conversation, member: member)
                                                switch result {
                                                case .loading, .failure:
                                                    // do nothing
                                                    break
                                                case .done:
                                                    #warning("Mutation")
                                                    self.conversation = result
                                                }
                                                viewModel.isLoading = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }, header: {
                    Text(R.string.localizable.membersLabel(conversation.baseConversation.numberOfMembers ?? 0))
                }, footer: {
                    pageActions
                })
            } else {
                EmptyView()
            }
        }
    }

    var pageActions: some View {
        Group {
            if let conversation = conversation.value,
               (conversation.baseConversation.numberOfMembers ?? 0) > PAGINATION_SIZE || viewModel.page > 0 {
                HStack(spacing: .l) {
                    Spacer()
                    Text("< \(R.string.localizable.previous())")
                        .onTapGesture {
                            Task {
                                await viewModel.loadPreviousMemberPage(for: course.id, conversationId: conversation.id)
                            }
                        }
                        .disabled(viewModel.page == 0)
                        .foregroundColor(viewModel.page == 0 ? .Artemis.buttonDisabledColor : .Artemis.artemisBlue)
                    Text("\(viewModel.page + 1)")
                    Text("\(R.string.localizable.next()) >")
                        .onTapGesture {
                            Task {
                                await viewModel.loadNextMemberPage(for: course.id, conversationId: conversation.id)
                            }
                        }
                        .disabled((conversation.baseConversation.numberOfMembers ?? 0) <= (viewModel.page + 1) * PAGINATION_SIZE)
                        .foregroundColor((conversation.baseConversation.numberOfMembers ?? 0) <= (viewModel.page + 1) * PAGINATION_SIZE ? .Artemis.buttonDisabledColor : .Artemis.artemisBlue)
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
    @Binding var conversation: DataState<Conversation>
    let course: Course

    @State private var showChangeNameAlert = false
    @State private var newName = ""

    @State private var showChangeTopicAlert = false
    @State private var newTopic = ""

    @State private var showChangeDescriptionAlert = false
    @State private var newDescription = ""

    var body: some View {
        if let conversation = conversation.value {
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
                    Task(priority: .userInitiated) {
                        #warning("Mutation")
                        self.conversation = await viewModel.editName(for: course.id, conversation: conversation, newName: newName)
                    }
                }
                Button(R.string.localizable.cancel(), role: .cancel) { }
            }
            .textCase(nil)
        }
    }
}

private extension InfoSection {
    var channelSections: some View {
        Group {
            if let conversation = conversation.value,
               let channel = conversation.baseConversation as? Channel {
                Section(R.string.localizable.nameLabel()) {
                    HStack {
                        Text(channel.name ?? R.string.localizable.noNameSet())
                        if channel.hasChannelModerationRights ?? false {
                            Spacer()
                            Button(action: { showChangeNameAlert = true }, label: {
                                Image(systemName: "pencil")
                            })
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
                                    Task(priority: .userInitiated) {
                                        #warning("Mutation")
                                        self.conversation = await viewModel.editTopic(for: course.id, conversation: conversation, newTopic: newTopic)
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
                                    Task(priority: .userInitiated) {
                                        #warning("Mutation")
                                        self.conversation = await viewModel.editDescription(for: course.id, conversation: conversation, newDescription: newDescription)
                                    }
                                }
                                Button(R.string.localizable.cancel(), role: .cancel) { }
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
