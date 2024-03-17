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

    @StateObject var viewModel: CreateChatViewModel

    var type: CreateOrAddToChatViewType

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                selectedUsers
                TextField(R.string.localizable.exampleUser(), text: $viewModel.searchText)
                    .textFieldStyle(ArtemisTextField())
                searchResults
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

extension CreateOrAddToChatView {
    init(courseId: Int, type: CreateOrAddToChatViewType = .createChat) {
        self.type = type
        self._viewModel = StateObject(wrappedValue: CreateChatViewModel(courseId: courseId))
    }
}

private extension CreateOrAddToChatView {
    var navigationTitle: String {
        switch type {
        case .createChat:
            return R.string.localizable.newConversationTitle()
        case .addToChat:
            return R.string.localizable.addUserTitle()
        }
    }

    var saveButtonLabel: String {
        switch type {
        case .createChat:
            return R.string.localizable.newConversationButtonLabel()
        case .addToChat:
            return R.string.localizable.addUserButtonLabel()
        }
    }

    var selectedUsers: some View {
        VStack(alignment: .leading) {
            ForEach(viewModel.selectedUsers, id: \.id) { user in
                if let name = user.name {
                    Button {
                        viewModel.selectedUsers.removeAll(where: { $0.id == user.id })
                    } label: {
                        Chip(text: name, backgroundColor: .Artemis.artemisBlue)
                    }
                }
            }
        }
    }

    var searchResults: some View {
        DataStateView(data: $viewModel.searchResults) {
            await viewModel.loadUsers()
        } content: { users in
            List {
                ForEach(
                    users.filter({ user in !viewModel.selectedUsers.contains(where: { $0.id == user.id }) }), id: \.id
                ) { user in
                    if let name = user.name {
                        Button {
                            if viewModel.selectedUsers.contains(user) {
                                viewModel.selectedUsers.removeAll(where: { $0.id == user.id })
                            } else {
                                viewModel.selectedUsers.append(user)
                            }
                        } label: {
                            Text(name)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CreateOrAddToChatView(
        viewModel: {
            let viewModel = CreateChatViewModel(courseId: 0)
            viewModel.selectedUsers = [
                MessagesServiceStub.alice,
                MessagesServiceStub.bob
            ]
            return viewModel
        }(),
        type: .createChat)
}
