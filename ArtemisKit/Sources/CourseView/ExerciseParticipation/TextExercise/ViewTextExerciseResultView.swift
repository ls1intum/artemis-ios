//
//  ViewTextExerciseResultView.swift
//
//
//  Created by Nityananda Zbil on 17.06.24.
//

import SharedModels
import SwiftUI

struct ViewTextExerciseResultView: View {
    @State var viewModel: EditTextExerciseViewModel

    var body: some View {
        EmptyView()
            .task {
                await viewModel.fetchSubmission()
            }
            .toolbar {
                ToolbarItemGroup(placement: .principal) {
                    SubmissionResultStatusView(exercise: viewModel.exercise)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ExerciseParticipationAssessmentButton(isAssessmentPresented: .constant(false))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension ViewTextExerciseResultView {
    init(exercise: Exercise, participationId: Int) {
        self.init(viewModel: EditTextExerciseViewModel(
            exercise: exercise,
            participationId: participationId,
            problem: URLRequest(url: URL(string: "example.org")!)))
    }
}
