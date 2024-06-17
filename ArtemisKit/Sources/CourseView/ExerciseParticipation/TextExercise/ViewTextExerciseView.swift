//
//  ViewTextExerciseView.swift
//
//
//  Created by Nityananda Zbil on 16.06.24.
//

import SharedModels
import SwiftUI

struct ViewTextExerciseView: View {
    @State var viewModel: EditTextExerciseViewModel

    var body: some View {
        VStack(alignment: .leading) {
            TextEditor(text: $viewModel.text)
                .disabled(true)
                .overlay {
                    RoundedRectangle(cornerRadius: .m)
                        .stroke(Color.Artemis.artemisBlue)
                }
        }
        .padding()
        .task {
            await viewModel.fetchSubmission()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle(R.string.localizable.viewSubmissionTitle())
    }
}

extension ViewTextExerciseView {
    init(exercise: Exercise, participationId: Int) {
        self.init(viewModel: EditTextExerciseViewModel(
            exercise: exercise,
            participationId: participationId,
            problem: nil))
    }
}
