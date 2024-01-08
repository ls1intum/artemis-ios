//
//  ModelingExerciseViewModel.swift
//
//
//  Created by Alexander Görtzen on 21.11.23.
//

import SwiftUI
import ApollonShared
import ApollonView
import SharedModels
import DesignLibrary

struct ViewModelingExerciseResultView: View {
    @StateObject var modelingViewModel: ModelingExerciseViewModel

    init(exercise: Exercise, participationId: Int) {
        self._modelingViewModel = StateObject(wrappedValue: ModelingExerciseViewModel(exercise: exercise,
                                                                                      participationId: participationId))
    }

    var body: some View {
        // TODO: Add Badges to indicate what was right and wrong. IS ADDED IN THE FOLLOWING PR.
        ZStack {
            if !modelingViewModel.diagramTypeUnsupported {
                if let model = modelingViewModel.umlModel, let type = model.type {
                    ApollonView(umlModel: model,
                                diagramType: type,
                                fontSize: 14.0,
                                themeColor: Color.Artemis.artemisBlue,
                                diagramOffset: CGPoint(x: 0, y: 0),
                                isGridBackground: true) {}
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle(R.string.localizable.viewResultTitle())
    }
}
