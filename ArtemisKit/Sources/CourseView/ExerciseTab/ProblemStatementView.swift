//
//  ProblemStatementView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 30.03.26.
//

import Common
import DesignLibrary
import SwiftUI

struct ProblemStatementView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var viewModel: ExerciseDetailViewModel

    var body: some View {
        if let exercise = viewModel.exercise.value {
            if case .quiz = exercise {
                EmptyView()
            } else {
                problemStatement(darkMode: colorScheme == .dark)
            }
        }
    }

    private func problemStatement(darkMode: Bool) -> some View {
        DataStateView(data: darkMode ? $viewModel.problemStatementRenderedDark : $viewModel.problemStatementRendered) {
            await viewModel.loadRenderedProblemStatement(darkMode: darkMode)
        } content: { problem in
            ArtemisWebView(
                html: problem,
                contentHeight: $viewModel.webViewHeight,
                isLoading: $viewModel.isWebViewLoading
            )
            .id("\(problem.hashValue)\(darkMode)")
            .frame(height: !problem.isEmpty ? viewModel.webViewHeight : 0)
            .allowsHitTesting(false)
            .loadingIndicator(isLoading: $viewModel.isWebViewLoading)
        }
        .onAppear {
            if darkMode, case .loading = viewModel.problemStatementRenderedDark {
                loadProblemStatement(darkMode: darkMode)
            } else if !darkMode, case .loading = viewModel.problemStatementRendered {
                loadProblemStatement(darkMode: darkMode)
            }
        }
    }

    private func loadProblemStatement(darkMode: Bool) {
        Task {
            await viewModel.loadRenderedProblemStatement(darkMode: darkMode)
        }
    }
}
