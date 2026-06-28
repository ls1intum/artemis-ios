//
//  IrisSessionListView.swift
//  ArtemisKit
//
//  Created by Senan Aslan on 25.05.26.
//

import Account
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
    @State private var showAiSettings = false

    private let course: Course

    public init(course: Course) {
        self.course = course
        _viewModel = State(wrappedValue: IrisSessionListViewModel(courseId: course.id))
    }

    private var selectedSession: Binding<IrisSessionPath?> {
        navigationController.selectedPathBinding($navigationController.selectedPath)
    }

    /// The user's AI usage choice. Seeded from the cached account and refreshed when the
    /// settings sheet reports a change, since the cached account is not observable.
    @State private var selectedLLMUsage: AiSelectionDecision? = UserSessionFactory.shared.user?.selectedLLMUsage

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
                    AiConsentView(selection: selectedLLMUsage, showSettings: $showAiSettings)
                }
            }
            .courseToolbar()
            .sheet(isPresented: $showAiSettings) {
                NavigationStack {
                    AiExperienceSettingsView { newSelection in
                        selectedLLMUsage = newSelection
                    }
                }
            }
        } detail: {
            if let path = navigationController.selectedPath as? IrisSessionPath {
                IrisChatView(
                    sessionPath: path,
                    session: viewModel.session(for: path.sessionId),
                    isCreatingSession: viewModel.isCreatingSession,
                    onNewChat: createAndOpenSession,
                    onDeleted: {
                        viewModel.removeSession(sessionId: path.sessionId)
                        navigationController.selectedPath = nil
                    },
                    onTitleChange: { newTitle in
                        viewModel.updateSessionTitle(sessionId: path.sessionId, title: newTitle)
                    },
                    onContextChange: { context in
                        viewModel.updateSessionContext(sessionId: path.sessionId, context: context)
                    })
                .id(path.sessionId)
            } else if let path = navigationController.selectedPath as? IrisStartChatPath {
                ProgressView()
                    .task(id: "startChat") {
                        if let newSession = await viewModel.createNewSession() {
                            navigationController.selectedPath = IrisSessionPath(
                                sessionId: newSession.id, defaultInput: path.inputText, coursePath: CoursePath(course: course))
                        }
                    }
            } else {
                SelectDetailView()
            }
        }
        .loadingIndicator(isLoading: $viewModel.isLoading)
        .alert(isPresented: viewModel.showError, error: viewModel.error, actions: {})
        .task { await viewModel.loadSessions() }
        .onChange(of: aiEnabled) { _, isEnabled in
            if isEnabled {
                Task { await viewModel.loadSessions() }
            }
        }
    }

    @ViewBuilder
    private func sessionList(viewModel: IrisSessionListViewModel) -> some View {
        @Bindable var viewModel = viewModel
        DataStateView(data: $viewModel.sessions) {
            await viewModel.loadSessions()
        } content: { _ in
            List(selection: selectedSession) {
                if viewModel.groupedSessions.isEmpty {
                    emptyState
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.groupedSessions) { group in
                        Section(group.title) {
                            ForEach(group.sessions) { session in
                                let path = IrisSessionPath(sessionId: session.id, coursePath: CoursePath(course: course))
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
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .refreshable { await viewModel.loadSessions() }
            .contentMargins(.bottom, 80, for: .scrollContent)
            .overlay(alignment: .bottomTrailing) {
                NewIrisSessionButton(isCreating: viewModel.isCreatingSession, action: createAndOpenSession)
                    .padding()
            }
        }
    }

    /// Empty state shown as a list row (rather than an overlay) so the list stays the
    /// scrollable surface and pull-to-refresh moves the screen, consistent with other tabs.
    @ViewBuilder private var emptyState: some View {
        if !viewModel.searchText.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            ContentUnavailableView {
                VStack(spacing: .m) {
                    Image("iris", bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.primary)
                        .frame(width: 80, height: 80)
                    Text(R.string.localizable.noChats())
                        .font(.headline)
                }
            } description: {
                Text(R.string.localizable.noChatsDescription())
            }
        }
    }

    /// Creates a session and navigates to it. Shared by the + button and the
    /// chat view's "New Chat" menu item.
    private func createAndOpenSession() {
        Task {
            if let newSession = await viewModel.createNewSession() {
                navigationController.selectedPath = IrisSessionPath(
                    sessionId: newSession.id, coursePath: CoursePath(course: course))
            }
        }
    }
}

/// Shown in place of the session list when the user has not opted into AI usage.
/// Explains where the AI setting lives via a breadcrumb whose final segment opens it directly.
private struct AiConsentView: View {
    let selection: AiSelectionDecision?
    @Binding var showSettings: Bool

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
            VStack(spacing: .s) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                settingsPath
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Breadcrumb to the AI setting; the last segment is a button that opens it directly.
    private var settingsPath: some View {
        HStack(spacing: .s) {
            segment(R.string.localizable.irisAiSettingsPathDashboard())
            arrow
            segment(R.string.localizable.irisAiSettingsPathAccount())
            arrow
            Button {
                showSettings = true
            } label: {
                Text(R.string.localizable.irisAiSettingsPathDestination())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Artemis.artemisBlue)
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private func segment(_ text: String) -> some View {
        Text(text).foregroundStyle(.secondary)
    }

    private var arrow: some View {
        Text("→").foregroundStyle(.tertiary)
    }
}

private struct IrisSessionRowView: View {
    let session: IrisSessionDTO

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.mode.icon)
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
            .frame(width: 60, height: 60, alignment: .center)
            .glassEffect(.clear.tint(.Artemis.artemisBlue).interactive(), in: .circle)
            .shadow(color: Color.gray.opacity(0.2), radius: .m)
        }
        .disabled(isCreating)
    }
}
