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
    @Bindable var viewModel: ExerciseDetailViewModel

    var body: some View {
        if let exercise = viewModel.exercise.value {
            if case .quiz = exercise {
                EmptyView()
            } else {
                DataStateView(data: $viewModel.problemStatementRendered) {
                    await viewModel.loadRenderedProblemStatement()
                } content: { problem in
                    ArtemisWebView(
                        html: problem,
                        contentHeight: $viewModel.webViewHeight,
                        isLoading: $viewModel.isWebViewLoading
                    )
                    .id(problem.hashValue)
                    .frame(height: !problem.isEmpty ? viewModel.webViewHeight : 0)
                    .allowsHitTesting(false)
                    .loadingIndicator(isLoading: $viewModel.isWebViewLoading)
                }
                .onAppear {
                    if case .loading = viewModel.problemStatementRendered {
                        Task {
                            await viewModel.loadRenderedProblemStatement()
                        }
                    }
                }
            }
        }
    }
}
