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

            Text(R.string.localizable.waitingForStart())
                .font(.title2)
            Text(R.string.localizable.waitingForStartDetail())
                .font(.footnote)
                .padding(.bottom)

            Button(R.string.localizable.refresh()) {
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

struct WaitForQuizEndView: View {
    var body: some View {
        VStack(alignment: .center, spacing: .m) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)

            Text(R.string.localizable.waitingForEnd())
                .font(.title2)
            Text(R.string.localizable.waitingForEndDetail())
                .font(.footnote)
                .padding(.bottom)
        }
        .padding()
        .background(Color.Artemis.artemisBlue.opacity(0.5), in: .rect(cornerRadius: .l))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
