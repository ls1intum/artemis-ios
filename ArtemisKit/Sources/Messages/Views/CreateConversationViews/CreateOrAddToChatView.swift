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

struct CreateOrAddToChatView: View {

    enum Configuration {
        case createChat
        case addToChat(Conversation)
    }

    @FocusState private var focused
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navigationController: NavigationController

    @StateObject var viewModel: CreateChatViewModel

    var configuration: Configuration

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                selectedUsers
                TextField(R.string.localizable.searchUsersLabel(), text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
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
                            switch configuration {
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
            .onAppear {
                focused = true
            }
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
        }
    }
}

extension CreateOrAddToChatView {
    init(courseId: Int, configuration: Configuration) {
        self.init(viewModel: CreateChatViewModel(courseId: courseId), configuration: configuration)
    }
}

private extension CreateOrAddToChatView {
    var navigationTitle: String {
        switch configuration {
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
                ForEach(viewModel.selectedUsers.reversed(), id: \.id) { user in
                    if let name = user.name {
                        Button {
                            viewModel.unstage(user: user)
                        } label: {
                            HStack {
                                ProfilePictureView(user: user, role: nil, course: .mock, size: 25)
                                    .allowsHitTesting(false)
                                Text(name)
                            }
                            .padding(.m)
                            .background(Color.Artemis.artemisBlue, in: .rect(cornerRadius: .m))
                        }.buttonStyle(.plain)
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
            if viewModel.searchText.count < 3 {
                ContentUnavailableView(R.string.localizable.enterAtLeast3Characters(),
                                       systemImage: "magnifyingglass")
            } else {
                List {
                    let displayedUsers = users.filter({ user in !viewModel.selectedUsers.contains(where: { $0.id == user.id }) })
                    ForEach(displayedUsers, id: \.id) { user in
                        if let name = user.name {
                            Button {
                                viewModel.stage(user: user)
                            } label: {
                                HStack {
                                    ProfilePictureView(user: user, role: nil, course: .mock, size: 25)
                                        .allowsHitTesting(false)
                                    Text(name)
                                }
                            }
                        }
                    }
                    if displayedUsers.isEmpty {
                        ContentUnavailableView(R.string.localizable.noMatchingUsers(),
                                               systemImage: "person.slash.fill")
                    }
                }
                .listStyle(.plain)
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
            viewModel.searchResults = .done(response: [
                MessagesServiceStub.charlie
            ])
            return viewModel
        }(),
        configuration: .createChat)
}
