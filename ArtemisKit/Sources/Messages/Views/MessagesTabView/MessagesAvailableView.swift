//
//  MessagesTabView.swift
//
//
//  Created by Sven Andabaka on 03.04.23.
//

import Common
import DesignLibrary
import Faq
import Navigation
import SharedModels
import SwiftUI

public struct MessagesAvailableView: View {

    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var navController: NavigationController
    @StateObject private var viewModel: MessagesAvailableViewModel

    @State var columnVisibilty: NavigationSplitViewVisibility = .doubleColumn

    @State private var searchText = ""

    @State private var isCodeOfConductPresented = false

    private var searchResults: [Conversation] {
        if searchText.isEmpty /*&& viewModel.filter == .all*/ {
            return []
        }
        return (viewModel.allConversations.value ?? []).filter {
            $0.baseConversation.conversationName.lowercased().contains(searchText.lowercased())
        }
    }

    private var selectedConversation: Binding<ConversationPath?> {
        navController.selectedPathBinding($navController.selectedPath)
    }

    public init(course: Course) {
        self._viewModel = StateObject(wrappedValue: MessagesAvailableViewModel(course: course))
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibilty) {
            List(selection: selectedConversation) {
                if !searchText.isEmpty {
                    if searchResults.isEmpty {
                        ContentUnavailableView.search
                    }
                    ForEach(searchResults) { conversation in
                        if let channel = conversation.baseConversation as? Channel {
                            ConversationRow(viewModel: viewModel, conversation: channel)
                        }
                        if let groupChat = conversation.baseConversation as? GroupChat {
                            ConversationRow(viewModel: viewModel, conversation: groupChat)
                        }
                        if let oneToOneChat = conversation.baseConversation as? OneToOneChat {
                            ConversationRow(viewModel: viewModel, conversation: oneToOneChat)
                        }
                    }.listRowBackground(Color.clear)
                } else {
                    DataStateView(data: $viewModel.allConversations) {
                        await viewModel.loadConversations()
                    } content: { conversations in
                        ConversationListView(viewModel: viewModel,
                                             conversations: conversations)
                    }

                    HStack {
                        Spacer()
                        Button {
                            isCodeOfConductPresented = true
                        } label: {
                            HStack {
                                Image(systemName: "info.circle")
                                Text(R.string.localizable.codeOfConduct())
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    // Empty row so that there is always space for floating button
                    Spacer()
                        .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .listRowSpacing(0.01)
            .listSectionSpacing(.compact)
            .searchable(text: $searchText)
            .refreshable {
                await viewModel.loadConversations()
            }
            .task {
                await viewModel.loadConversations()
            }
            .task {
                await viewModel.subscribeToConversationMembershipTopic()
            }
            .overlay(alignment: .bottomTrailing) {
                CreateOrAddChannelButton(viewModel: viewModel)
                    .padding()
            }
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
            .loadingIndicator(isLoading: $viewModel.isLoading)
            .sheet(isPresented: $isCodeOfConductPresented) {
                NavigationStack {
                    ScrollView {
                        CodeOfConductView(course: viewModel.course)
                    }
                    .contentMargins(.l, for: .scrollContent)
                    .navigationTitle(R.string.localizable.codeOfConduct())
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                isCodeOfConductPresented = false
                            } label: {
                                Text(R.string.localizable.done())
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.course.title ?? R.string.localizable.loading())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackToRootButton(placement: .navBar, sizeClass: sizeClass)
                }
            }
        } detail: {
            NavigationStack(path: $navController.tabPath) {
                Group {
                    if let path = navController.selectedPath as? ConversationPath {
                        ConversationPathView(path: path)
                            .id(path.id)
                    } else {
                        SelectDetailView()
                    }
                }
                .modifier(NavigationDestinationMessagesModifier())
                .navigationDestination(for: FaqPath.self) { path in
                    FaqPathView(path: path)
                }
            }
        }
        // Add a file picker here, inside the navigation it doesn't work sometimes
        .supportsFilePicker()
    }
}
