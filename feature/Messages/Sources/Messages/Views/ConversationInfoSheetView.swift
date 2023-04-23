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

struct ConversationInfoSheetView: View {

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
                    Button("Leave Conversation") {
                        Task(priority: .userInitiated) {
                            await viewModel.leaveConversation(for: course.id, conversationId: conversation.id)
                        }
                    }
                    if let channel = conversation.baseConversation as? Channel {
                        Button("Archive Channel") {
                            Task(priority: .userInitiated) {
                                await viewModel.archiveChannel(for: course.id, conversationId: conversation.id)
                            }
                        }
                        Button("Unarchive Channel") {
                            Task(priority: .userInitiated) {
                                await viewModel.unarchiveChannel(for: course.id, conversationId: conversation.id)
                            }
                        }
                        Button("Delete Channel") {
                            Task(priority: .userInitiated) {
                                await viewModel.deleteChannel(for: course.id, conversationId: conversation.id)
                            }
                        }
                    }
                }.sheet(isPresented: $showAddMemberSheet, onDismiss: {
                    Task {
                        self.conversation = await viewModel.reloadConversation(for: course.id, conversationId: conversation.id)
                        await viewModel.loadMembers(for: course.id, conversationId: conversation.id)
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
                            Text(member.name ?? "Unknown")
                                .contextMenu {
                                    Button("Remove user") {
                                        Task(priority: .userInitiated) {
                                            await viewModel.removeMemberFromConversation(for: course.id, conversationId: conversation.id, member: member)
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
               (conversation.baseConversation.numberOfMembers ?? 0) > 2 || viewModel.page > 0 {
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
                        .disabled((conversation.baseConversation.numberOfMembers ?? 0) <= (viewModel.page + 1) * 2)
                        .foregroundColor((conversation.baseConversation.numberOfMembers ?? 0) <= (viewModel.page + 1) * 2 ? .Artemis.buttonDisabledColor : .Artemis.artemisBlue)
                    Spacer()
                }.font(.body)
            } else {
                EmptyView()
            }
        }
    }
}
