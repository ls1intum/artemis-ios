//
//  ModelingExerciseView.swift
//
//
//  Created by Alexander Görtzen on 21.11.23.
//

import SwiftUI
import ApollonShared
import ApollonEdit
import SharedModels
import DesignLibrary
import Common
import Navigation

struct ModelingExerciseView: View {
    @StateObject var modelingVM: ModelingExerciseViewModel

    init(exercise: Exercise, participationId: Int, problemStatementURL: URLRequest) {
        self._modelingVM = StateObject(wrappedValue: ModelingExerciseViewModel(exercise: exercise,
                                                                               participationId: participationId,
                                                                               problemStatementURL: problemStatementURL))
    }

    var body: some View {
        ZStack {
            if let model = modelingVM.umlModel, let type = model.type {
                ApollonEdit(umlModel: model, diagramType: type, fontSize: 14.0, diagramOffset: CGPoint(x: 0, y: 0), isGridBackground: true)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            HStack {
                                ProblemStatementButton(modelingVM: modelingVM)
                                SubmitButton(modelingVM: modelingVM)
                            }
                        }
                    }
            }
        }.task {
            await modelingVM.initSubmission()
            modelingVM.setup()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct SubmitButton: View {
    @StateObject var modelingVM: ModelingExerciseViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navigationController: NavigationController

    var body: some View {
        Button("Submit") {
            Task {
                await modelingVM.submitSubmission()
            }
            //dismiss()
            navigationController.popToRoot()
        }.buttonStyle(ArtemisButton())
    }
}

struct ProblemStatementButton: View {
    @StateObject var modelingVM: ModelingExerciseViewModel
    @State private var isShowingProblemStatement = false
    @State private var isWebViewLoading = true

    var body: some View {
        Button(action: {
            isShowingProblemStatement.toggle()
        }) {
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
        .sheet(isPresented: $isShowingProblemStatement) {
            VStack(alignment: .center) {
                ArtemisWebView(urlRequest: $modelingVM.problemStatementURL,
                               isLoading: $isWebViewLoading)
                .loadingIndicator(isLoading: $isWebViewLoading)
            }.padding(.m)
        }
    }
}
