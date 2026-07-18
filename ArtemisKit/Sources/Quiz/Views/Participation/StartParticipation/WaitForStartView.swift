//
//  WaitForStartView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 13.07.26.
//

import SwiftUI

struct WaitForQuizStartView: View {
    let viewModel: QuizParticipationViewModel

    var body: some View {
        // TODO: Styling
        Text("Waiting for Quiz Start")
            .onDisappear {
                viewModel.onSyncDisappear()
            }
    }
}
