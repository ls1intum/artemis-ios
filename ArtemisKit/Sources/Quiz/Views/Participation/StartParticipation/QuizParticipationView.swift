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

    public init(exercise: QuizExercise, courseId: Int) {
        self._viewModel = State(initialValue: .init(exercise: exercise, courseId: courseId))
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
                    if let questions = quiz.exercise?.quizQuestions {
                        QuizView(startTime: startTime,
                                 endTime: startTime?.addingTimeInterval(duration),
                                 questionsWithoutSolution: questions)
                    } else {
                        StartQuizView()
                    }
                case .StudentQuizParticipationWithSolutions(let quiz):
                    let duration = Double(quiz.exercise?.duration ?? 0)
                    let batch = quiz.exercise?.quizBatches?.last
                    let startTime = batch?.ended ?? false ? .now : batch?.startTime
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
            // TODO: Show solutions
            if newValue == true {
                dismiss()
            }
        }
    }
}
