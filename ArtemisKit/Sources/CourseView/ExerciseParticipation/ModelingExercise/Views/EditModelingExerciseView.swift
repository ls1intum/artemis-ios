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

    @State private var isSubmissionAlertPresented = false
    @State private var isSubmissionSuccessful = false

    @State private var isProblemStatementPresented = false
    @State private var isWebViewLoading = true

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
                        ExerciseParticipationProblemButton(isProblemStatementPresented: $isProblemStatementPresented)
                        ExerciseParticipationSubmitButton(
                            delegate: ExerciseParticipationSubmitButton.Delegate {
                                try await modelingViewModel.submitSubmission()
                            },
                            isSubmissionAlertPresented: $isSubmissionAlertPresented,
                            isSubmissionSuccessful: $isSubmissionSuccessful)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert(isPresented: $isSubmissionAlertPresented) {
            alert
        }
        .sheet(isPresented: $isProblemStatementPresented) {
            sheet
        }
    }
}

extension EditModelingExerciseView {
    init(exercise: Exercise, participationId: Int, problemStatementURL: URLRequest) {
        self.init(modelingViewModel: ModelingExerciseViewModel(
            exercise: exercise,
            participationId: participationId,
            problemStatementURL: problemStatementURL))
    }
}

private extension EditModelingExerciseView {
    var alert: Alert {
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

    var sheet: some View {
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
                                isProblemStatementPresented = false
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
