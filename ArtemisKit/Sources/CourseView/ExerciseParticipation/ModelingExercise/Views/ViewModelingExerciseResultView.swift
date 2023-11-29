import SwiftUI
import ApollonShared
import ApollonView
import SharedModels
import DesignLibrary

struct ViewModelingExerciseResultView: View {
    @StateObject var modelingVM: ModelingExerciseViewModel

    init(exercise: Exercise, participationId: Int, resultId: Int) {
        self._modelingVM = StateObject(wrappedValue: ModelingExerciseViewModel(exercise: exercise,
                                                                               participationId: participationId,
                                                                               resultId: resultId))
    }

    var body: some View {
        // TODO: Add Badges to indicate what was right and wrong.
        ZStack {
            if !modelingVM.diagramTypeUnsupported {
                if let model = modelingVM.umlModel, let type = model.type {
                    ApollonView(umlModel: model,
                                diagramType: type,
                                fontSize: 14.0,
                                diagramOffset: CGPoint(x: 0, y: 0),
                                isGridBackground: true)
                }
            } else {
                ArtemisHintBox(text: R.string.localizable.diagramTypeNotSupported(), hintType: .warning)
                    .padding(.horizontal, .l)
            }
        }
        .task {
            await modelingVM.initSubmission()
            modelingVM.setup()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle("Result")
    }
}
