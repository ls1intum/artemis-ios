//
//  CreateChatView.swift
//  
//
//  Created by Sven Andabaka on 23.04.23.
//

import SwiftUI
import SharedModels
import DesignLibrary
import Navigation

struct CreateChatView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navigationController: NavigationController

    @StateObject private var viewModel: CreateChatViewModel

    init(courseId: Int) {
        self._viewModel = StateObject(wrappedValue: CreateChatViewModel(courseId: courseId))
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
                .navigationTitle("New Conversation")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(R.string.localizable.cancel()) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create Conversation") {
                            Task(priority: .userInitiated) {
                                let newChatId = await viewModel.createChat()

                                if let newChatId {
                                    dismiss()
                                    navigationController.goToCourseConversation(courseId: viewModel.courseId, conversationId: newChatId)
                                }
                            }
                        }.disabled(viewModel.selectedUsers.isEmpty)
                    }
                }
        }
    }
}
