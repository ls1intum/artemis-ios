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
                } content: { prob in
                    ArtemisWebView(
                        html: prob,
                        contentHeight: $viewModel.webViewHeight,
                        isLoading: $viewModel.isWebViewLoading
                    )
                    .frame(height: viewModel.webViewHeight)
                    .allowsHitTesting(false)
                    .loadingIndicator(isLoading: $viewModel.isWebViewLoading)
                }
                .task {
                    if case .loading = viewModel.problemStatementRendered {
                        await viewModel.loadRenderedProblemStatement()
                    }
                }
            }
        }
    }
}
