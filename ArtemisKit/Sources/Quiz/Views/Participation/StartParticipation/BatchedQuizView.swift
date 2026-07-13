//
//  BatchedQuizView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 13.07.26.
//

import DesignLibrary
import SwiftUI

struct BatchedQuizView: View {
    @Bindable var viewModel: QuizParticipationViewModel

    var body: some View {
        DataStateView(data: $viewModel.participation) {
            await viewModel.startParticipation()
        } content: { participation in
            switch participation {
            case .StudentQuizParticipationWithQuestions(let quiz):
                let duration = Double(quiz.exercise?.duration ?? 0)
                let batch = quiz.exercise?.quizBatches?.last
                QuizView(endTime: batch?.startTime?.addingTimeInterval(duration),
                         questionsWithoutSolution: quiz.exercise?.quizQuestions)
            case .StudentQuizParticipationWithSolutions(let quiz):
                let duration = Double(quiz.exercise?.duration ?? 0)
                let batch = quiz.exercise?.quizBatches?.last
                QuizView(endTime: batch?.startTime?.addingTimeInterval(duration),
                         questionsWithSolution: quiz.exercise?.quizQuestions)
            default:
                StartBatchView(isIndividual: false)
            }
        }
        .environment(viewModel)
        .task(id: "startParticipation") {
            await viewModel.startParticipation()
        }
    }
}
