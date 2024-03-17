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
        NavigationStack {
            VStack(alignment: .leading) {
                selectedUsers
                TextField(R.string.localizable.searchUsersLabel(), text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, .l)
                searchResults
            }
            .loadingIndicator(isLoading: $viewModel.isLoading)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
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
            return ""
        }
    }

    var saveButtonLabel: LocalizedStringKey {
        "\(R.string.localizable.addUserButtonLabelPrefix()) ^[\(viewModel.selectedUsers.count) \(R.string.localizable.addUserButtonLabelSuffix())](inflect:true)"
    }

    var selectedUsers: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(viewModel.selectedUsers, id: \.id) { user in
                    if let name = user.name {
                        Button(role: .destructive) {
                            viewModel.selectedUsers.removeAll(where: { $0.id == user.id })
                        } label: {
                            Chip(text: name, backgroundColor: .Artemis.artemisBlue)
                        }
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.l, for: .scrollContent)
        .listRowInsets(.none)
        .frame(height: viewModel.selectedUsers.isEmpty ? 0 : nil)
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
            .listStyle(.plain)
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
            viewModel.searchResults = .done(response: [
                MessagesServiceStub.charlie
            ])
            return viewModel
        }(),
        type: .createChat)
}
