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
    @StateObject var modelingViewModel: ModelingExerciseViewModel

    init(exercise: Exercise, participationId: Int, problemStatementURL: URLRequest) {
        self._modelingViewModel = StateObject(wrappedValue: ModelingExerciseViewModel(exercise: exercise,
                                                                                      participationId: participationId,
                                                                                      problemStatementURL: problemStatementURL))
    }

    var body: some View {
        ZStack {
            if !modelingViewModel.diagramTypeUnsupported {
                if let model = modelingViewModel.umlModel, let type = model.type {
                    ApollonEdit(umlModel: Binding(
                        get: { modelingViewModel.umlModel ?? UMLModel() },
                        set: { modelingViewModel.umlModel = $0 }),
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
            await modelingViewModel.fetchSubmission()
            modelingViewModel.setupUMLModel()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !modelingViewModel.diagramTypeUnsupported {
                    HStack {
                        ProblemStatementButton(modelingViewModel: modelingViewModel)
                        SubmitButton(modelingViewModel: modelingViewModel)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct SubmitButton: View {
    @ObservedObject var modelingViewModel: ModelingExerciseViewModel

    var body: some View {
        Button {
            Task {
                await modelingViewModel.submitSubmission()
            }
        } label: {
            Text(R.string.localizable.submitSubmission())
        }.buttonStyle(ArtemisButton())
    }
}

struct ProblemStatementButton: View {
    @ObservedObject var modelingViewModel: ModelingExerciseViewModel
    @State private var isShowingProblemStatement = false
    @State private var isWebViewLoading = true

    var body: some View {
        Button {
            isShowingProblemStatement = true
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
        .sheet(isPresented: $isShowingProblemStatement) {
            NavigationView {
                VStack(alignment: .leading) {
                    if modelingViewModel.problemStatementURL != nil {
                        ArtemisWebView(urlRequest: Binding(
                            get: { modelingViewModel.problemStatementURL ?? URLRequest(url: URL(string: "")!) },
                            set: { modelingViewModel.problemStatementURL = $0 }),
                                       isLoading: $isWebViewLoading)
                        .loadingIndicator(isLoading: $isWebViewLoading)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button {
                                    isShowingProblemStatement = false
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
}