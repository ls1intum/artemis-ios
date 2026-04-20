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
                ZStack {
                    problemStatement(darkMode: true)
                        .opacity(colorScheme == .dark ? 1 : 0)
                    problemStatement(darkMode: false)
                        .opacity(colorScheme == .dark ? 0 : 1)
                }
                .onChange(of: colorScheme, initial: true) {
                    if colorScheme == .dark, case .loading = viewModel.problemStatementRenderedDark {
                        loadProblemStatement(darkMode: true)
                    } else if colorScheme != .dark, case .loading = viewModel.problemStatementRendered {
                        loadProblemStatement(darkMode: false)
                    }
                }
            }
        }
    }

    private func problemStatement(darkMode: Bool) -> some View {
        DataStateView(data: darkMode ? $viewModel.problemStatementRenderedDark : $viewModel.problemStatementRendered) {
            await viewModel.loadRenderedProblemStatement(darkMode: darkMode)
        } content: { html in
            ArtemisWebView(
                html: html,
                contentHeight: $viewModel.webViewHeight,
                isLoading: $viewModel.isWebViewLoading
            )
            .id("\(html.hashValue)")
            .frame(height: viewModel.webViewHeight + webViewPadding)
            .allowsHitTesting(false)
            .loadingIndicator(isLoading: $viewModel.isWebViewLoading)
        }
    }

    private func loadProblemStatement(darkMode: Bool) {
        Task {
            await viewModel.loadRenderedProblemStatement(darkMode: darkMode)
            viewModel.isWebViewLoading = true
        }
    }

    private var webViewPadding: CGFloat {
        // UML diagrams slightly change height between light and dark mode
        // This adds some spacing to ensure they are not cut off when switching to dark mode
        if let problemStatement = viewModel.exercise.value?.baseExercise.problemStatement,
           let regex = try? Regex("@startuml") {
            return CGFloat(problemStatement.matches(of: regex).count) * 20
        }
        return 0
    }
}
