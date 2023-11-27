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
            return R.string.localizable.newConversationTitle()
        case .addToChat:
            return R.string.localizable.addUserTitle()
        }
    }

    private var saveButtonLabel: String {
        switch type {
        case .createChat:
            return R.string.localizable.newConversationButtonLabel()
        case .addToChat:
            return R.string.localizable.addUserButtonLabel()
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    ForEach(viewModel.selectedUsers, id: \.id) { user in
                        if let name = user.name {
                            Button(action: {
                                viewModel.selectedUsers.removeAll(where: { $0.id == user.id })
                            }, label: {
                                Chip(text: name, backgroundColor: .Artemis.artemisBlue)
                            })
                        }
                    }
                }
                TextField(R.string.localizable.exampleUser(), text: $viewModel.searchText)
                    .textFieldStyle(ArtemisTextField())
                DataStateView(data: $viewModel.searchResults,
                              retryHandler: { await viewModel.loadUsers() }) { users in
                    List {
                        ForEach(users.filter({ user in !viewModel.selectedUsers.contains(where: { $0.id == user.id }) }), id: \.id) { user in
                            if let name = user.name {
                                Button(action: {
                                    if viewModel.selectedUsers.contains(user) {
                                        viewModel.selectedUsers.removeAll(where: { $0.id == user.id })
                                    } else {
                                        viewModel.selectedUsers.append(user)
                                    }
                                }, label: {
                                    Text(name)
                                })
                            }
                        }
                    }
                }
            }
                .loadingIndicator(isLoading: $viewModel.isLoading)
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
                            viewModel.isLoading = true
                            Task(priority: .userInitiated) {
                                switch type {
                                case .createChat:
                                    let newChatId = await viewModel.createChat()
                                    viewModel.isLoading = false
                                    if let newChatId {
                                        dismiss()
                                        navigationController.goToCourseConversation(courseId: viewModel.courseId, conversationId: newChatId)
                                    }
                                case .addToChat(let conversation):
                                    let success = await viewModel.addUsersToConversation(conversation)
                                    viewModel.isLoading = false
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
