//
//  QuizParticipationView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.07.26.
//

import DesignLibrary
import SharedModels
import SwiftUI

public struct QuizParticipationView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: QuizParticipationViewModel
    @State private var showDismissConfirmation = false

    public init(exercise: QuizExercise, courseId: Int) {
        self._viewModel = State(initialValue: .init(exercise: exercise, courseId: courseId))
    }

    public var body: some View {
        NavigationStack {
            DataStateView(data: $viewModel.participation) {
                await viewModel.startParticipation()
            } content: { participation in
                QuizParticipation(participation: participation)
            }
            // We need both types, otherwise @Environment only finds the subclass
            .environment(viewModel as QuizViewModel)
            .environment(viewModel)
            .task(id: "startParticipation") {
                await viewModel.startParticipation()
            }
            .navigationTitle(viewModel.exercise.title ?? "")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) {
                        if viewModel.submissionSuccessful != true {
                            showDismissConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .confirmationDialog(R.string.localizable.notSubmittedWarning(), isPresented: $showDismissConfirmation, titleVisibility: .visible) {
                        Button(R.string.localizable.close()) {
                            dismiss()
                        }
                    }
                }
            }
            .opacity(viewModel.waitingForResults ? 0.5 : 1)
            .allowsHitTesting(!viewModel.waitingForResults)
        }
        .interactiveDismissDisabled()
        .overlay {
            if viewModel.waitingForResults {
                WaitForQuizEndView()
            }
        }
    }
}

private struct QuizParticipation: View {
    @State private var startDate = Date.now
    let participation: DTO.StudentQuizParticipation

    var body: some View {
        switch participation {
        case .liveQuiz(let quiz):
            let duration = Double(quiz.exercise?.duration ?? 0)
            let batch = quiz.exercise?.quizBatches?.last
            let startTime = batch?.ended ?? false ? startDate : batch?.startTime
            if let questions = quiz.exercise?.quizQuestions {
                QuizView(startTime: startTime,
                         endTime: startTime?.addingTimeInterval(duration),
                         questionsWithoutSolution: questions)
            } else {
                StartQuizView()
            }
        case .afterQuizEnd(let quiz):
            let duration = Double(quiz.exercise?.duration ?? 0)
            let batch = quiz.exercise?.quizBatches?.last
            let startTime = batch?.ended ?? false ? startDate : batch?.startTime
            if let questions = quiz.exercise?.quizQuestions {
                QuizView(startTime: startTime,
                         endTime: startTime?.addingTimeInterval(duration),
                         questionsWithSolution: questions)
            } else {
                StartQuizView()
            }
        default:
            StartQuizView()
        }
    }
}
