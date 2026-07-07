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
        switch viewModel.exercise.quizMode {
        case .synchronized:
            Text("Sync") // Check for batch -> if no batch, websocket
        case .batched:
            Text("Batch") // Password thing?
        case .individual:
            Text("Individual") // Empty password?
        default:
            Text("Unknown Quiz Type")
        }
        Text("Hi")
    }
}
