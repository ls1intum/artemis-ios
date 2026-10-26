import Foundation
import SharedModels
import SwiftUI

struct SubmitTrainingAnswerButton: View {
    @Environment(QuizTrainingViewModel.self) private var viewModel
    let questionId: Int64?
    let isRated: Bool?
    let answer: DTO.SubmittedAnswerFromLiveClient

    var body: some View {
        Color.clear.frame(height: 0)
            .onAppear { viewModel.updateDraft(answer) }
            .onChange(of: try? JSONEncoder().encode(answer)) { _, _ in viewModel.updateDraft(answer) }
            .toolbar {
                if viewModel.phase != .uncertain {
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            Task {
                                if viewModel.hasSubmitted { await viewModel.advance() } else if let questionId, let isRated {
                                    await viewModel.submitAnswer(questionId: questionId, isRated: isRated, answer: answer)
                                }
                            }
                        } label: {
                            if viewModel.phase == .submitting {
                                ProgressView(TrainingCopy.text("submitting"))
                            } else { Text(TrainingCopy.text(viewModel.hasSubmitted ? "next" : "submit")) }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.phase == .submitting || questionId == nil || isRated == nil)
                    }
                }
            }
    }
}
