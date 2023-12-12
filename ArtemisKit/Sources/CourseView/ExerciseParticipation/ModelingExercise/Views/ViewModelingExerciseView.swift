import SwiftUI
import ApollonShared
import ApollonView
import SharedModels
import DesignLibrary

struct ViewModelingExerciseView: View {
    @StateObject var modelingVM: ModelingExerciseViewModel

    init(exercise: Exercise, participationId: Int) {
        self._modelingVM = StateObject(wrappedValue: ModelingExerciseViewModel(exercise: exercise, participationId: participationId))
    }

    var body: some View {
        ZStack {
            if !modelingVM.diagramTypeUnsupported {
                if let model = modelingVM.umlModel, let type = model.type {
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
            await modelingVM.onAppear()
            modelingVM.setup()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle("Submission")
    }
}
