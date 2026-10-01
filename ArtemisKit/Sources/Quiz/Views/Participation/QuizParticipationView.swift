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
    @State private var startDate = Date.now

    public init(exercise: QuizExercise, courseId: Int) {
        self._viewModel = State(initialValue: .init(exercise: exercise, courseId: courseId))
    }

    public var body: some View {
        NavigationStack {
            DataStateView(data: $viewModel.participation) {
                await viewModel.startParticipation()
            } content: { participation in
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
                    .confirmationDialog("You have not submitted yet. Cancel anyways?", isPresented: $showDismissConfirmation, titleVisibility: .visible) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .opacity(viewModel.waitingForResults ? 0.5 : 1)
        .overlay {
            if viewModel.waitingForResults {
                WaitForQuizEndView()
            }
        }
    }
}
