//
//  QuizSubmissionStatusIndicator.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 13.07.26.
//

import SwiftUI

struct QuizSubmissionStatusIndicator: View {
    @Environment(QuizParticipationViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            Text("Question \(viewModel.selectedQuestion + 1)/\(viewModel.questionCount)")
                .fixedSize()
            if viewModel.isLiveQuiz {
                // TODO: Actual status
                Text("Status: Saved")
                    .font(.footnote)
                    .fixedSize()
            }
        }
        .padding(.horizontal, .m)
        .fixedSize()
    }
}
