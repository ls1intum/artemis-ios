//
//  QuizTrainingView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 01.06.26.
//

import SwiftUI

public struct QuizTrainingView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: LeaderboardViewModel

    let courseId: Int

    public init(courseId: Int) {
        self.courseId = courseId
        self._viewModel = State(initialValue: LeaderboardViewModel(courseId: courseId))
    }

    public var body: some View {
        NavigationStack {
            List {
                LeaderboardView(viewModel: viewModel)
            }
            .navigationTitle(R.string.localizable.quizTraining())
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(R.string.localizable.done()) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    NavigationLink {
                        QuizTraingQuestionsView(courseId: courseId)
                    } label: {
                        Label("Start Training", systemImage: "dumbbell")
                    }
                    .labelStyle(.titleAndIcon)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canStartRated)
                }
            }
        }
    }

    var canStartRated: Bool {
        guard let leaderboard = viewModel.leaderboardData.value else { return false }
        return leaderboard.currentUserEntry.dueDate < leaderboard.currentTime
    }
}
