//
//  StartQuizView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 13.07.26.
//

import SwiftUI

struct StartQuizView: View {
    @Environment(QuizParticipationViewModel.self) private var viewModel

    var body: some View {
        switch viewModel.exercise.quizMode {
        case .synchronized:
            WaitForQuizStartView(viewModel: viewModel)
                .onAppear {
                    viewModel.startWaitingForQuizStart()
                }
        case .batched:
            StartBatchView(isIndividual: false)
        case .individual:
            StartBatchView(isIndividual: true)
        default:
            Text("Unknown Quiz Type")
        }
    }
}
