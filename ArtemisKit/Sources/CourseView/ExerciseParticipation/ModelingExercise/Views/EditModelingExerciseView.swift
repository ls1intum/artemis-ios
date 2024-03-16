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
    @State private var showSubmissionAlert = false
    @State private var isSubmissionSuccessful = false

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
                        SubmitButton(modelingViewModel: modelingViewModel, showSubmissionAlert: $showSubmissionAlert, isSubmissionSuccessful: $isSubmissionSuccessful)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert(isPresented: $showSubmissionAlert) {
            if isSubmissionSuccessful {
                return Alert(
                    title: Text(R.string.localizable.successfulSubmissionAlertTitle()),
                    message: Text(R.string.localizable.successfulSubmissionAlertMessage())
                )
            } else {
                return Alert(
                    title: Text(R.string.localizable.failedSubmissionAlertTitle()),
                    message: Text(R.string.localizable.failedSubmissionAlertMessage())
                )
            }
        }
    }
}

struct SubmitButton: View {
    @ObservedObject var modelingViewModel: ModelingExerciseViewModel
    @Binding var showSubmissionAlert: Bool
    @Binding var isSubmissionSuccessful: Bool
    @State private var isSubmitting = false

    var body: some View {
        Button {
            submit()
        } label: {
            ZStack {
                Text(R.string.localizable.submitSubmission())
                    .opacity(isSubmitting ? 0 : 1)
                // Show a Progress View, whilst the submision is being submitted
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.Artemis.primaryButtonTextColor))
                }
            }
        }
        .buttonStyle(ArtemisButton(buttonColor: showSubmissionAlert ?
                                   (isSubmissionSuccessful ? Color.Artemis.resultSuccess : Color.Artemis.resultFailedColor) :
                                    Color.Artemis.primaryButtonColor,
                                   buttonTextColor: Color.Artemis.primaryButtonTextColor))
        .disabled(isSubmitting)
    }

    private func submit() {
        isSubmitting = true
        Task {
            do {
                try await modelingViewModel.submitSubmission()
                isSubmissionSuccessful = true
            } catch {
                isSubmissionSuccessful = false
            }
            withAnimation {
                isSubmitting = false
                showSubmissionAlert.toggle()
            }
        }
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
