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

    public var body: some View {
        @Bindable var viewModel = viewModel
        NavigationSplitView(columnVisibility: .constant(.all)) {
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
            .refreshable { await viewModel.loadSessions() }
            .contentMargins(.bottom, 80, for: .scrollContent)
            .overlay {
                if viewModel.sessions.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("No Iris Sessions", systemImage: "brain.head.profile")
                }
            }
            .overlay(alignment: .bottomTrailing) {
                NewIrisSessionButton(viewModel: viewModel, courseId: courseId)
                    .padding()
            }
            .courseToolbar()
        } detail: {
            if let path = navigationController.selectedPath as? IrisSessionPath {
                IrisChatView(sessionPath: path)
                    .id(path.id)
            } else {
                SelectDetailView()
            }
        }
        .task { await viewModel.loadSessions() }
        .loadingIndicator(isLoading: $viewModel.isLoading)
        .alert(isPresented: viewModel.showError, error: viewModel.error, actions: {})
    }

    private var selectedSession: Binding<IrisSessionPath?> {
        navigationController.selectedPathBinding($navigationController.selectedPath)
    }
}
