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

    public init(exercise: QuizExercise) {
        self._viewModel = State(initialValue: .init(exercise: exercise))
    }

    public var body: some View {
        NavigationStack {
            DataStateView(data: $viewModel.participation) {
                await viewModel.startParticipation()
            } content: { participation in
                switch participation {
                case .StudentQuizParticipationWithQuestions(let quiz):
                    let duration = Double(quiz.exercise?.duration ?? 0)
                    let batch = quiz.exercise?.quizBatches?.last
                    let startTime = batch?.ended ?? false ? .now : batch?.startTime
                    QuizView(endTime: startTime?.addingTimeInterval(duration),
                             questionsWithoutSolution: quiz.exercise?.quizQuestions)
                case .StudentQuizParticipationWithSolutions(let quiz):
                    let duration = Double(quiz.exercise?.duration ?? 0)
                    let batch = quiz.exercise?.quizBatches?.last
                    let startTime = batch?.ended ?? false ? .now : batch?.startTime
                    QuizView(endTime: startTime?.addingTimeInterval(duration),
                             questionsWithSolution: quiz.exercise?.quizQuestions)
                default:
                    StartQuizView()
                }
            }
            .environment(viewModel)
            .task(id: "startParticipation") {
                await viewModel.startParticipation()
            }
            .navigationTitle(viewModel.exercise.title ?? "")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .onChange(of: viewModel.submissionSuccessful) { _, newValue in
            if newValue == true {
                dismiss()
            }
        }
    }
}
