//
//  ModelingExerciseView.swift
//
//
//  Created by Alexander Görtzen on 21.11.23.
//

import ApollonEdit
import ApollonShared
import Common
import DesignLibrary
import SharedModels
import SwiftUI

struct ModelingExerciseView: View {
    @StateObject var modelingViewModel: ModelingExerciseViewModel

    init(exercise: Exercise, participationId: Int, problemStatementURL: URLRequest) {
        self._modelingViewModel = StateObject(wrappedValue: ModelingExerciseViewModel(
            exercise: exercise,
            participationId: participationId,
            problemStatementURL: problemStatementURL)
        )
    }

    var body: some View {
        Group {
            if let model = modelingViewModel.umlModel, let type = model.type {
                ApollonEdit(
                    umlModel: model,
                    diagramType: type,
                    fontSize: 14.0,
                    diagramOffset: CGPoint(x: 0, y: 0),
                    isGridBackground: true
                )
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        HStack {
                            ProblemStatementButton(modelingViewModel: modelingViewModel)
                            SubmitButton(modelingViewModel: modelingViewModel)
                        }
                    }
                }
            }
        }
        .task {
            await modelingViewModel.initSubmission()
            modelingViewModel.setup()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct SubmitButton: View {
    @StateObject var modelingViewModel: ModelingExerciseViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        Button("Submit") {
            Task {
                await modelingViewModel.submitSubmission()
            }
            presentationMode.wrappedValue.dismiss()
        }
        .buttonStyle(ArtemisButton())
    }
}

struct ProblemStatementButton: View {
    @StateObject var modelingViewModel: ModelingExerciseViewModel
    @State private var isProblemStatementPresented = false
    @State private var isWebViewLoading = true

    var body: some View {
        Button {
            isProblemStatementPresented.toggle()
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
        .sheet(isPresented: $isProblemStatementPresented) {
            VStack(alignment: .center) {
                ArtemisWebView(urlRequest: $modelingViewModel.problemStatementURL, isLoading: $isWebViewLoading)
                    .loadingIndicator(isLoading: $isWebViewLoading)
            }
            .padding(.m)
        }
    }
}
