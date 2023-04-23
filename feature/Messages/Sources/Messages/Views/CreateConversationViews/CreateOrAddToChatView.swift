//
//  CreateOrAddToChatView.swift
//  
//
//  Created by Sven Andabaka on 23.04.23.
//

import SwiftUI
import SharedModels
import DesignLibrary
import Navigation

enum CreateOrAddToChatViewType {
    case createChat
    case addToChat(Conversation)
}

struct CreateOrAddToChatView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navigationController: NavigationController

    @StateObject private var viewModel: CreateChatViewModel

    private var type: CreateOrAddToChatViewType

    init(courseId: Int, type: CreateOrAddToChatViewType = .createChat) {
        self.type = type
        self._viewModel = StateObject(wrappedValue: CreateChatViewModel(courseId: courseId))
    }

    private var navigationTitle: String {
        switch type {
        case .createChat:
            return "New Conversation"
        case .addToChat:
            return "Add User(s)"
        }
    }

    private var saveButtonLabel: String {
        switch type {
        case .createChat:
            return "Create Conversation"
        case .addToChat:
            return "Add User(s)"
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    ForEach(viewModel.selectedUsers, id: \.id) { user in
                        Button(action: {
                            viewModel.selectedUsers.removeAll(where: { $0.id == user.id })
                        }, label: {
                            Chip(text: user.name ?? "Unknown", backgroundColor: .Artemis.artemisBlue)
                        })
                    }
                }
                TextField("ex. Stefan", text: $viewModel.searchText)
                    .textFieldStyle(ArtemisTextField())
                DataStateView(data: $viewModel.searchResults,
                              retryHandler: { await viewModel.loadUsers() }) { users in
                    List {
                        ForEach(users, id: \.id) { user in
                            Button(action: {
                                if viewModel.selectedUsers.contains(user) {
                                    viewModel.selectedUsers.removeAll(where: { $0.id == user.id })
                                } else {
                                    viewModel.selectedUsers.append(user)
                                }
                            }, label: {
                                Text(user.name ?? "Unknown")
                            })
                        }
                    }
                }
            }
                .padding(.l)
                .navigationTitle(navigationTitle)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(R.string.localizable.cancel()) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(saveButtonLabel) {
                            Task(priority: .userInitiated) {
                                switch type {
                                case .createChat:
                                    let newChatId = await viewModel.createChat()

                                    if let newChatId {
                                        dismiss()
                                        navigationController.goToCourseConversation(courseId: viewModel.courseId, conversationId: newChatId)
                                    }
                                case .addToChat(let conversation):
                                    let success = await viewModel.addUsersToConversation(conversation)

                                    if success {
                                        dismiss()
                                    }
                                }
                            }
                        }.disabled(viewModel.selectedUsers.isEmpty)
                    }
                }
                .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
        }
    }
}
