//
//  ModelingExerciseViewModel.swift
//
//
//  Created by Alexander Görtzen on 21.11.23.
//

import SwiftUI
import ApollonShared
import ApollonEdit
import SharedModels
import DesignLibrary

struct EditModelingExerciseView: View {
    @StateObject var modelingVM: ModelingExerciseViewModel

    init(exercise: Exercise, participationId: Int, problemStatementURL: URLRequest) {
        self._modelingVM = StateObject(wrappedValue: ModelingExerciseViewModel(exercise: exercise,
                                                                               participationId: participationId,
                                                                               problemStatementURL: problemStatementURL))
    }

    var body: some View {
        ZStack {
            if !modelingVM.diagramTypeUnsupported {
                if let model = modelingVM.umlModel, let type = model.type {
                    ApollonEdit(umlModel: Binding(
                        get: { modelingVM.umlModel ?? UMLModel() },
                        set: { modelingVM.umlModel = $0 }),
                                diagramType: type,
                                fontSize: 14.0,
                                themeColor: Color.Artemis.artemisBlue,
                                diagramOffset: CGPoint(x: 0, y: 0),
                                isGridBackground: true)
                }
            } else {
                ArtemisHintBox(text: R.string.localizable.diagramTypeNotSupported(), hintType: .warning)
                    .padding(.horizontal, .l)
            }
        }
        .task {
            await modelingVM.onAppear()
            modelingVM.setup()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !modelingVM.diagramTypeUnsupported {
                    HStack {
                        ProblemStatementButton(modelingVM: modelingVM)
                        SubmitButton(modelingVM: modelingVM)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct SubmitButton: View {
    @ObservedObject var modelingVM: ModelingExerciseViewModel

    var body: some View {
        Button("Submit") {
            Task {
                await modelingVM.submitSubmission()
            }
        }.buttonStyle(ArtemisButton())
    }
}

struct ProblemStatementButton: View {
    @ObservedObject var modelingVM: ModelingExerciseViewModel
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
            NavigationView {
                VStack(alignment: .center) {
                    if let problemStatementURL = modelingVM.problemStatementURL {
                        ArtemisWebView(urlRequest: Binding(
                            get: { modelingVM.problemStatementURL ?? URLRequest(url: URL(string: "")!) },
                            set: { modelingVM.problemStatementURL = $0 }),
                                       isLoading: $isWebViewLoading)
                        .loadingIndicator(isLoading: $isWebViewLoading)
                    }
                }
                .padding(.m)
            }
        }
    }
}
