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
import Notifications
import SharedModels
import SwiftUI

public struct MessagesAvailableView: View {

    @EnvironmentObject var navController: NavigationController
    @StateObject private var viewModel: MessagesAvailableViewModel

    @State var columnVisibilty: NavigationSplitViewVisibility = .doubleColumn

    private var selectedConversation: Binding<ConversationPath?> {
        navController.selectedPathBinding($navController.selectedPath)
    }

    public init(course: Course) {
        self._viewModel = StateObject(wrappedValue: MessagesAvailableViewModel(course: course))
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibilty) {
            DataStateView(data: $viewModel.allConversations) {
                await viewModel.loadConversations()
            } content: { conversations in
                ConversationListView(viewModel: viewModel,
                                     conversations: conversations,
                                     selectedConversation: selectedConversation)
            }
            .scrollContentBackground(.hidden)
            .listRowSpacing(0.01)
            .listSectionSpacing(.compact)
            .refreshable {
                await viewModel.loadConversations()
            }
            .task {
                await viewModel.loadConversations()
            }
            .onAppear {
                viewModel.subscribeToWebsocketUpdates()
            }
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
            .loadingIndicator(isLoading: $viewModel.isLoading)
            .sheet(isPresented: $viewModel.isCodeOfConductPresented) {
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
                                viewModel.isCodeOfConductPresented = false
                            } label: {
                                Text(R.string.localizable.done())
                            }
                        }
                    }
                }
            }
            .courseToolbar()
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
    }
}
