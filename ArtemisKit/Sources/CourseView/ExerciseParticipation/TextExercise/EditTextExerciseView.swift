//
//  EditTextExerciseView.swift
//
//
//  Created by Nityananda Zbil on 10.12.23.
//

import DesignLibrary
import SwiftUI

public struct EditTextExerciseView: View {

    @State var viewModel: EditTextExerciseViewModel = .init()

    public init() {}

    public var body: some View {
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
                    Button("Submit") {
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

private extension EditTextExerciseView {
    var sheet: some View {
        NavigationView {
            VStack(alignment: .leading) {
//                if modelingViewModel.problemStatementURL != nil {
//                    ArtemisWebView(urlRequest: Binding(
//                        get: { modelingViewModel.problemStatementURL ?? URLRequest(url: URL(string: "")!) },
//                        set: { modelingViewModel.problemStatementURL = $0 }),
//                                   isLoading: $isWebViewLoading)
//                    .loadingIndicator(isLoading: $isWebViewLoading)
                if true {
                    EmptyView(
                    )
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
            }
            .padding(.m)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EditTextExerciseView()
    }
}
