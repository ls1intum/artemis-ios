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
    @Binding var course: DataState<Course>

    @State private var showAddMemberSheet = false

    var body: some View {
        NavigationView {
            DataStateView(data: $course, retryHandler: { }) { course in
                DataStateView(data: $conversation, retryHandler: { }) { conversation in
                    List {
                        infoSection
                        membersSection
                        actionsSection
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

    var actionsSection: some View {
        Group {
            if let course = course.value,
               let conversation = conversation.value {
                Section("Settings") {
                    Button("Add users") {
                        showAddMemberSheet = true
                    }
                    if let channel = conversation.baseConversation as? Channel {
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
                        Button("Delete Channel") {
                            viewModel.isLoading = true
                            Task(priority: .userInitiated) {
                                await viewModel.deleteChannel(for: course.id, conversationId: conversation.id)
                                viewModel.isLoading = false
                            }
                        }.foregroundColor(.Artemis.badgeDangerColor)
                    }
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

    var infoSection: some View {
        Group {
            if let course = course.value,
               let conversation = conversation.value {
                if let channel = conversation.baseConversation as? Channel {
                    Section("Name") {
                        Text(channel.name ?? "No name set ...")
                    }
                    Section("Topic") {
                        Text(channel.topic ?? "No topic set ...")
                    }
                    Section("Description") {
                        Text(channel.description ?? "No description set ...")
                    }
                }
                if let groupChat = conversation.baseConversation as? GroupChat {
                    Section("Name") {
                        Text(groupChat.name ?? "No name set ...")
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
            }
        }
    }

    var membersSection: some View {
        Group {
            if let course = course.value,
               let conversation = conversation.value {
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
                                    if UserSession.shared.user?.login != member.login {
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
            if let course = course.value,
               let conversation = conversation.value,
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
