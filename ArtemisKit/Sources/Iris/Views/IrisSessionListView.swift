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
import SwiftUI

public struct IrisSessionListView: View {
    @EnvironmentObject private var navigationController: NavigationController
    @State private var viewModel: IrisSessionListViewModel

    private let courseId: Int

    public init(courseId: Int) {
        self.courseId = courseId
        _viewModel = State(wrappedValue: IrisSessionListViewModel(courseId: courseId))
    }

    private var selectedSession: Binding<IrisSessionPath?> {
        navigationController.selectedPathBinding($navigationController.selectedPath)
    }

    public var body: some View {
        @Bindable var viewModel = viewModel
        NavigationSplitView(columnVisibility: .constant(.all)) {
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
                                        Task { await viewModel.deleteSession(sessionId: session.id) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
                .overlay {
                    if viewModel.groupedSessions.isEmpty && !viewModel.searchText.isEmpty {
                        ContentUnavailableView.search(text: viewModel.searchText)
                    }
                }
                .refreshable { await viewModel.loadSessions() }
                .contentMargins(.bottom, 80, for: .scrollContent)
                .overlay(alignment: .bottomTrailing) {
                    NewIrisSessionButton(viewModel: viewModel, courseId: courseId)
                        .padding()
                }
            }
            .courseToolbar()
        } detail: {
            if let path = navigationController.selectedPath as? IrisSessionPath {
                IrisChatView(sessionPath: path, onDeleted: {
                    navigationController.selectedPath = nil
                })
                .id(path.id)
            } else {
                SelectDetailView()
            }
        }
        .loadingIndicator(isLoading: $viewModel.isLoading)
        .task { await viewModel.loadSessions() }
    }
}

private struct IrisSessionRowView: View {
    let session: IrisSessionDTO

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: modeIcon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title ?? "New Chat")
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
    @EnvironmentObject private var navigationController: NavigationController
    @Bindable var viewModel: IrisSessionListViewModel
    let courseId: Int

    var body: some View {
        Button {
            Task {
                await viewModel.createNewSession()
            }
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(.white)
                .font(.title2)
                .padding()
                .background(Color.Artemis.artemisBlue, in: .circle)
                .shadow(color: Color.gray.opacity(0.2), radius: .m)
        }
    }
}
