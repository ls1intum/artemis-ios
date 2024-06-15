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
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                HStack {
                    Button {
                        viewModel.isProblemStatementPresented = true
                    } label: {
                        Image(systemName: "newspaper")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.vertical, .m)
                            .padding(.horizontal, .l)
                            .background {
                                RoundedRectangle(cornerRadius: 4)
                                    .foregroundColor(Color.Artemis.primaryButtonColor)
                            }
                    }
                    Button(R.string.localizable.submitSubmission()) {
                        viewModel.isSubmitted = true
                    }
                    .buttonStyle(ArtemisButton())
                    .disabled(viewModel.isSubmitted)
                }
            }
        }
        .sheet(isPresented: $viewModel.isProblemStatementPresented) {
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
                            viewModel.isProblemStatementPresented = false
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
