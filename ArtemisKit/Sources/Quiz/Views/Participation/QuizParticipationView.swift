//
//  QuizParticipationView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.07.26.
//

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
            Group {
                switch viewModel.exercise.quizMode {
                case .synchronized:
                    SynchronizedQuizView(viewModel: viewModel)
                case .batched:
                    Text("Batch Quiz not implemented") // Password thing?
                    // Join with pass (https://artemis-test4.artemis.cit.tum.de/api/quiz/quiz-exercises/680/join), body {"password":"00275317"}
                    /* Response
                     {
                         "id": 153,
                         "started": false,
                         "ended": false
                     }
                     */
                    // SUBSCRIBE /topic/courses/35/quizExercises/153 (id from join)
                    // -> Quiz like synchronized
                    BatchedQuizView(viewModel: viewModel)
                case .individual:
                    IndividualQuizView(viewModel: viewModel)
                default:
                    Text("Unknown Quiz Type")
                }
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
    }
}
