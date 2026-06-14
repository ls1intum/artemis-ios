//
//  IrisSessionListView.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 25.05.26.
//

import Common
import DesignLibrary
import Navigation
import Notifications
import SharedModels
import SwiftUI
import UserStore

public struct IrisSessionListView: View {
    @EnvironmentObject private var navigationController: NavigationController
    @State private var viewModel: IrisSessionListViewModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn

    private let courseId: Int

    public init(courseId: Int) {
        self.courseId = courseId
        _viewModel = State(wrappedValue: IrisSessionListViewModel(courseId: courseId))
    }

    private var selectedSession: Binding<IrisSessionPath?> {
        navigationController.selectedPathBinding($navigationController.selectedPath)
    }

    /// The user's AI usage choice, read from the cached account.
    private var selectedLLMUsage: AiSelectionDecision? {
        UserSessionFactory.shared.user?.selectedLLMUsage
    }

    /// Iris may only be used when the user opted into cloud or local AI.
    private var aiEnabled: Bool {
        selectedLLMUsage?.isAIEnabled ?? false
    }

    public var body: some View {
        @Bindable var viewModel = viewModel
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Group {
                if aiEnabled {
                    sessionList(viewModel: viewModel)
                } else {
                    AiConsentView(selection: selectedLLMUsage)
                }
            }
            .courseToolbar()
        } detail: {
            if let path = navigationController.selectedPath as? IrisSessionPath {
                IrisChatView(
                    sessionPath: path,
                    isCreatingSession: viewModel.isCreatingSession,
                    onNewChat: createAndOpenSession,
                    onDeleted: {
                        viewModel.removeSession(sessionId: path.sessionId)
                        navigationController.selectedPath = nil
                    },
                    onTitleChange: { newTitle in
                        viewModel.updateSessionTitle(sessionId: path.sessionId, title: newTitle)
                    })
                .id(path.sessionId)
            } else {
                SelectDetailView()
            }
        }
        .loadingIndicator(isLoading: $viewModel.isLoading)
        .alert(isPresented: viewModel.showError, error: viewModel.error, actions: {})
        .task { await viewModel.loadSessions() }
    }

    @ViewBuilder
    private func sessionList(viewModel: IrisSessionListViewModel) -> some View {
        @Bindable var viewModel = viewModel
        DataStateView(data: $viewModel.sessions) {
            await viewModel.loadSessions()
        } content: { _ in
            List(selection: selectedSession) {
                    ForEach(viewModel.groupedSessions) { group in
                        Section(group.title) {
                            ForEach(group.sessions) { session in
                                let path = IrisSessionPath(session: session, coursePath: CoursePath(id: courseId))
                                NavigationLink(value: path) {
                                    IrisSessionRowView(session: session)
                                }
                                .tag(path)
                                .navigationLinkIndicatorVisibility(.hidden)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task {
                                            let didDelete = await viewModel.deleteSession(sessionId: session.id)
                                            if didDelete,
                                               (navigationController.selectedPath as? IrisSessionPath)?.sessionId == session.id {
                                                navigationController.selectedPath = nil
                                            }
                                        }
                                    } label: {
                                        Label(R.string.localizable.delete(), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
                .overlay {
                    if viewModel.groupedSessions.isEmpty {
                        if !viewModel.searchText.isEmpty {
                            ContentUnavailableView.search(text: viewModel.searchText)
                        } else {
                            VStack(spacing: .m) {
                                Image("iris", bundle: .module)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(.primary)
                                    .frame(width: 80, height: 80)
                                VStack(spacing: .xs) {
                                    Text(R.string.localizable.noChats())
                                        .font(.headline)
                                    Text(R.string.localizable.noChatsDescription())
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .refreshable { await viewModel.loadSessions() }
                .contentMargins(.bottom, 80, for: .scrollContent)
                .overlay(alignment: .bottomTrailing) {
                    NewIrisSessionButton(isCreating: viewModel.isCreatingSession, action: createAndOpenSession)
                        .padding()
                }
        }
    }

    /// Creates a session and navigates to it. Shared by the + button and the
    /// chat view's "New Chat" menu item.
    private func createAndOpenSession() {
        Task {
            if let newSession = await viewModel.createNewSession() {
                navigationController.selectedPath = IrisSessionPath(
                    session: newSession, coursePath: CoursePath(id: courseId))
            }
        }
    }
}

/// Shown in place of the session list when the user has not opted into AI usage.
/// The choice is changed from the account menu.
private struct AiConsentView: View {
    let selection: AiSelectionDecision?

    private var message: String {
        selection == .noAI
            ? R.string.localizable.irisAiUsageDeclined()
            : R.string.localizable.irisAiUsageNotChosen()
    }

    var body: some View {
        VStack(spacing: .m) {
            Image("iris", bundle: .module)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.primary)
                .frame(width: 80, height: 80)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct IrisSessionRowView: View {
    let session: IrisSessionDTO

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: modeIcon)
                .font(.title3)
                .foregroundStyle(.primary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title ?? R.string.localizable.newChat())
                    .lineLimit(1)

                if let entityName = session.entityName {
                    Text(entityName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(session.creationDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var modeIcon: String {
        switch session.mode {
        case .programmingExercise:
            "keyboard"
        case .textExercise:
            "character"
        case .course:
            "graduationcap"
        case .lecture:
            "inset.filled.rectangle.and.person.filled"
        default:
            "questionmark"
        }
    }
}

private struct NewIrisSessionButton: View {
    let isCreating: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "plus")
                }
            }
            .foregroundStyle(.white)
            .font(.title2)
            .padding()
            .background(Color.Artemis.artemisBlue, in: .circle)
            .shadow(color: Color.gray.opacity(0.2), radius: .m)
        }
        .disabled(isCreating)
    }
}
