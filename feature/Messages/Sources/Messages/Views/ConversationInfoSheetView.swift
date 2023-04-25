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
            DataStateView(data: $conversation, retryHandler: { self.conversation = await viewModel.reloadConversation(for: course.id, conversationId: conversationId) }) { conversation in
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

    private var canLeaveConversation: Bool {
        guard let conversation = conversation.value else { return false }

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

    private var canAddUsers: Bool {
        guard let conversation = conversation.value else { return false }

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

    private var canRemoveUsers: Bool {
        canAddUsers
    }

    private var actionsSection: some View {
        Group {
            if let conversation = conversation.value {
                Section("Settings") {
                    if canAddUsers {
                        Button("Add users") {
                            showAddMemberSheet = true
                        }
                    }
                    if let channel = conversation.baseConversation as? Channel,
                       channel.hasChannelModerationRights ?? false {
                        if channel.isArchived ?? false {
                            Button("Unarchive Channel") {
                                viewModel.isLoading = true
                                Task(priority: .userInitiated) {
                                    let result = await viewModel.unarchiveChannel(for: course.id, conversationId: conversation.id)

                                    switch result {
                                    case .loading, .failure:
                                        // do nothing
                                        break
                                    case .done:
                                        self.conversation = result
                                    }

                                    viewModel.isLoading = false
                                }
                            }.foregroundColor(.Artemis.badgeWarningColor)
                        } else {
                            Button("Archive Channel") {
                                viewModel.isLoading = true
                                Task(priority: .userInitiated) {
                                    let result = await viewModel.archiveChannel(for: course.id, conversationId: conversation.id)
                                    switch result {
                                    case .loading, .failure:
                                        // do nothing
                                        break
                                    case .done:
                                        self.conversation = result
                                    }
                                    viewModel.isLoading = false
                                }
                            }.foregroundColor(.Artemis.badgeWarningColor)
                        }
                    }
                    if canLeaveConversation {
                        Button("Leave Conversation") {
                            viewModel.isLoading = true
                            Task(priority: .userInitiated) {
                                let success = await viewModel.leaveConversation(for: course.id, conversation: conversation)

                                if success {
                                    navigationController.goToCourseConversations(courseId: course.id)
                                } else {
                                    viewModel.isLoading = false
                                }
                            }
                        }.foregroundColor(.Artemis.badgeDangerColor)
                    }
                }.sheet(isPresented: $showAddMemberSheet, onDismiss: {
                    viewModel.isLoading = true
                    Task {
                        let result = await viewModel.reloadConversation(for: course.id, conversationId: conversation.id)

                        switch result {
                        case .loading, .failure:
                            // do nothing
                            break
                        case .done:
                            self.conversation = result
                        }

                        await viewModel.loadMembers(for: course.id, conversationId: conversation.id)
                        viewModel.isLoading = false
                    }
                }) {
                    CreateOrAddToChatView(courseId: course.id, type: .addToChat(conversation))
                }
            }
        }
    }

    private var membersSection: some View {
        Group {
            if let conversation = conversation.value {
                Section(content: {
                    DataStateView(data: $viewModel.members,
                                  retryHandler: { await viewModel.loadMembers(for: course.id, conversationId: conversation.id) }) { members in
                        ForEach(members, id: \.id) { member in
                            HStack {
                                Text(member.name ?? "Unknown")
                                Spacer()
                                if UserSession.shared.user?.login == member.login {
                                    Chip(text: "You", backgroundColor: .Artemis.artemisBlue)
                                }
                            }
                                .contextMenu {
                                    if UserSession.shared.user?.login != member.login,
                                       canRemoveUsers {
                                        Button("Remove user") {
                                            viewModel.isLoading = true
                                            Task(priority: .userInitiated) {
                                                let result = await viewModel.removeMemberFromConversation(for: course.id, conversation: conversation, member: member)

                                                switch result {
                                                case .loading, .failure:
                                                    // do nothing
                                                    break
                                                case .done:
                                                    self.conversation = result
                                                }

                                                viewModel.isLoading = false
                                            }
                                        }
                                    }
                                }
                        }
                    }
                }, header: {
                    Text("Members (\(conversation.baseConversation.numberOfMembers ?? 0))")
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
                    Text("< Previous")
                        .onTapGesture {
                            Task {
                                await viewModel.loadPreviousMemberPage(for: course.id, conversationId: conversation.id)
                            }
                        }
                        .disabled(viewModel.page == 0)
                        .foregroundColor(viewModel.page == 0 ? .Artemis.buttonDisabledColor : .Artemis.artemisBlue)
                    Text("\(viewModel.page + 1)")
                    Text("Next >")
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
            if let channel = conversation.baseConversation as? Channel {
                Section("Name") {
                    HStack {
                        Text(channel.name ?? "No name set ...")
                        if channel.hasChannelModerationRights ?? false {
                            Spacer()
                            Button(action: { showChangeNameAlert = true }, label: {
                                Image(systemName: "pencil")
                            })
                        }
                    }
                }
                Section("Topic") {
                    HStack {
                        Text(channel.topic ?? "No topic set ...")
                        if channel.hasChannelModerationRights ?? false {
                            Spacer()
                            Button(action: { showChangeTopicAlert = true }, label: {
                                Image(systemName: "pencil")
                            })
                                .alert("Edit Topic", isPresented: $showChangeTopicAlert) {
                                    TextField("New Topic", text: $newTopic)
                                    Button("OK") {
                                        viewModel.isLoading = true
                                        Task(priority: .userInitiated) {
                                            self.conversation = await viewModel.editTopic(for: course.id, conversation: conversation, newTopic: newTopic)
                                        }
                                    }
                                    Button("Cancel", role: .cancel) { }
                                }
                                .textCase(nil)
                        }
                    }
                }
                Section("Description") {
                    HStack {
                        Text(channel.description ?? "No description set ...")
                        if channel.hasChannelModerationRights ?? false {
                            Spacer()
                            Button(action: { showChangeDescriptionAlert = true }, label: {
                                Image(systemName: "pencil")
                            })
                                .alert("Edit Description", isPresented: $showChangeDescriptionAlert) {
                                    TextField("New Description", text: $newDescription)
                                    Button("OK") {
                                        viewModel.isLoading = true
                                        Task(priority: .userInitiated) {
                                            self.conversation = await viewModel.editDescription(for: course.id, conversation: conversation, newDescription: newDescription)
                                        }
                                    }
                                    Button("Cancel", role: .cancel) { }
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
            if let groupChat = conversation.baseConversation as? GroupChat {
                Section("Name") {
                    HStack {
                        Text(groupChat.name ?? "No name set ...")
                        if groupChat.isMember ?? false {
                            Spacer()
                            Button(action: { showChangeNameAlert = true }, label: {
                                Image(systemName: "pencil")
                            })
                        }
                    }
                }
            }
            Section("More info") {
                Text("Created by: \(conversation.baseConversation.creator?.name ?? "Unknown")")
                if let creationDate = conversation.baseConversation.creationDate {
                    Text("Created on: \(creationDate.mediumDateShortTime)")
                } else {
                    Text("Created on: Unknown")
                }
            }
                .onAppear {
                    newName = conversation.baseConversation.conversationName
                }
                .alert("Edit Name", isPresented: $showChangeNameAlert) {
                    TextField("New Name", text: $newName)
                    Button("OK") {
                        viewModel.isLoading = true
                        Task(priority: .userInitiated) {
                            self.conversation = await viewModel.editName(for: course.id, conversation: conversation, newName: newName)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .textCase(nil)
        }
    }
}
