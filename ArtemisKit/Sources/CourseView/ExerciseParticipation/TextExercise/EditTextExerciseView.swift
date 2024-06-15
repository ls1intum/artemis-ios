//
//  EditTextExerciseView.swift
//
//
//  Created by Nityananda Zbil on 10.12.23.
//

import DesignLibrary
import SharedModels
import SwiftUI

struct EditTextExerciseView: View {

    @State var viewModel: EditTextExerciseViewModel

    var body: some View {
        VStack(alignment: .leading) {
            TextEditor(text: $viewModel.text)
                .overlay {
                    RoundedRectangle(cornerRadius: .m)
                        .stroke(Color.Artemis.artemisBlue)
                }
        }
        .padding([.horizontal, .bottom])
        .onChange(of: viewModel.text) {
            viewModel.isSubmitted = false
        }
        .navigationTitle(viewModel.exercise.baseExercise.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                HStack {
                    ExerciseParticipationProblemButton(isProblemPresented: $viewModel.isProblemPresented)
                    ExerciseParticipationSubmitButton(
                        submit: {

                        },
                        isSubmissionAlertPresented: .constant(false),
                        isSubmissionSuccessful: .constant(false))
                }
            }
        }
        .sheet(isPresented: $viewModel.isProblemPresented) {
            sheet
        }
    }
}

extension EditTextExerciseView {
    init(exercise: Exercise, problem: URLRequest) {
        self.init(viewModel: EditTextExerciseViewModel(exercise: exercise, problem: problem))
    }
}

private extension EditTextExerciseView {
    var sheet: some View {
        NavigationView {
            VStack(alignment: .leading) {
                ArtemisWebView(
                    urlRequest: $viewModel.problem,
                    isLoading: $viewModel.isWebViewLoading
                )
                .loadingIndicator(isLoading: $viewModel.isWebViewLoading)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            viewModel.isProblemPresented = false
                        } label: {
                            Text(R.string.localizable.close())
                        }
                    }
                }
            }
            .padding(.m)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EditTextExerciseView(
            exercise: .text(exercise: TextExercise(id: 1)),
            problem: URLRequest(url: URL(string: "example.org")!))
    }
}
