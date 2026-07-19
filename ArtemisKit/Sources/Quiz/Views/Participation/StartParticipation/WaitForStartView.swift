//
//  WaitForStartView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 13.07.26.
//

import DesignLibrary
import SwiftUI

struct WaitForQuizStartView: View {
    @Bindable var viewModel: QuizParticipationViewModel

    var body: some View {
        VStack(alignment: .center, spacing: .m) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)

            Text("Waiting for Quiz Start")
                .font(.title2)
            Text("The quiz has not started yet. This page will refresh automatically when the quiz starts.")
                .font(.footnote)

            Button("Refresh") {
                Task {
                    await viewModel.startParticipation()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.loadingQuizStart)
            .loadingIndicator(isLoading: $viewModel.loadingQuizStart)
        }
        .padding()
        .background(Color.Artemis.artemisBlue.opacity(0.5), in: .rect(cornerRadius: .l))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onDisappear {
            viewModel.onSyncDisappear()
        }
    }
}
