import SwiftUI
import ApollonShared
import ApollonEdit
import SharedModels
import Common

struct ModelingExerciseView: View {
    @StateObject var modelingVM: ModelingViewModel
    
    init(exercise: Exercise, participationId: Int) {
        self._modelingVM = StateObject(wrappedValue: ModelingViewModel(exercise: exercise, participationId: participationId))
    }
    
    var body: some View {
        VStack {
            if let modelType = modelingVM.umlModel?.type?.rawValue {
                Text(modelType)
            }
            if let model = modelingVM.umlModel, let type = model.type {
                ApollonEdit(umlModel: model, diagramType: type, fontSize: 14.0, diagramOffset: CGPoint(x: 0, y: 0), isGridBackground: true)
            }
        }.task {
            await modelingVM.initSubmission()
            modelingVM.setup()
        }
    }
}
