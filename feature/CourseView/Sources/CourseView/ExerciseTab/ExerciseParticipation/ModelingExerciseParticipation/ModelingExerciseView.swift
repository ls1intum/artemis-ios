import SwiftUI
import ApollonShared
import ApollonEdit
import SharedModels
import DesignLibrary
import Common

struct ModelingExerciseView: View {
    @StateObject var modelingVM: ModelingViewModel

    init(exercise: Exercise, participationId: Int, problemStatementURL: URLRequest) {
        self._modelingVM = StateObject(wrappedValue: ModelingViewModel(exercise: exercise, participationId: participationId, problemStatementURL: problemStatementURL))
    }

    var body: some View {
        ZStack {
            if let model = modelingVM.umlModel, let type = model.type {
                ApollonEdit(umlModel: model, diagramType: type, fontSize: 14.0, diagramOffset: CGPoint(x: 0, y: 0), isGridBackground: true)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            HStack {
                                ProblemStatementButton(modelingVM: modelingVM)
                                SubmitButton()
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
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        Button("Submit") {
            presentationMode.wrappedValue.dismiss()
        }.buttonStyle(ArtemisButton())
    }
}

struct ProblemStatementButton: View {
    @StateObject var modelingVM: ModelingViewModel
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
