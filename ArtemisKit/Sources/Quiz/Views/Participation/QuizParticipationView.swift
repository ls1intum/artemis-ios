//
//  QuizParticipationView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.07.26.
//

import SharedModels
import SwiftUI

public struct QuizParticipationView: View {

    @State private var viewModel: QuizParticipationViewModel

    public init(exercise: QuizExercise) {
        self._viewModel = State(initialValue: .init(exercise: exercise))
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.exercise.quizMode {
                case .synchronized:
                    SynchronizedQuizView(viewModel: viewModel)
                case .batched:
                    Text("Batch Quiz not implemented") // Password thing?
                case .individual:
                    Text("Individual Quiz not implemented") // Empty password?
                default:
                    Text("Unknown Quiz Type")
                }
            }
            .navigationTitle(viewModel.exercise.title ?? "")
            .toolbarTitleDisplayMode(.inline)
        }
    }
}
