import SwiftUI
import ApollonShared
import ApollonView
import SharedModels
import DesignLibrary

struct ViewModelingExerciseResultView: View {
    @StateObject var modelingVM: ModelingExerciseViewModel
    @State var isStatusViewClicked = false

    init(exercise: Exercise, participationId: Int, resultId: Int) {
        self._modelingVM = StateObject(wrappedValue: ModelingExerciseViewModel(exercise: exercise,
                                                                               participationId: participationId,
                                                                               resultId: resultId))
    }

    var body: some View {
        ZStack {
            if !modelingVM.diagramTypeUnsupported {
                if let model = modelingVM.umlModel, let type = model.type {
                    ApollonView(umlModel: model,
                                diagramType: type,
                                fontSize: 14.0,
                                diagramOffset: modelingVM.diagramOffset,
                                isGridBackground: true) {
                        Canvas(rendersAsynchronously: true) { context, size in
                            modelingVM.renderHighlights(&context, size: size)
                        } symbols: {
                            modelingVM.generatePossibleSymbols()
                        }
                        .onTapGesture { tapLocation in
                            modelingVM.selectItem(at: tapLocation)
                        }
                    }
                }
                FeedbackViewPopOver(modelingVM: modelingVM, showFeedback: $modelingVM.showFeedback)
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
            ToolbarItemGroup(placement: .principal) {
                SubmissionResultStatusView(exercise: modelingVM.exercise)
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !modelingVM.unreferencedFeedbacks.isEmpty {
                    UnreferencedFeedbackView(modelingVM: modelingVM, isStatusViewClicked: $isStatusViewClicked)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct FeedbackViewPopOver: View {
    @ObservedObject var modelingVM: ModelingExerciseViewModel
    @Binding var showFeedback: Bool

    var body: some View {
        if showFeedback,
           modelingVM.selectedItem != nil,
           let feedbackId = modelingVM.selectedFeedbackId,
           let feedback = modelingVM.getFeedback(byId: feedbackId) {
            VStack {
                Spacer()
                HStack {
                    VStack {
                        if let reference = feedback.reference {
                            Text(reference.components(separatedBy: ":")[0])
                                .foregroundColor(.white)
                                .bold()
                        }
                        if let text = feedback.text {
                            Text("Feedback: \(text)")
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        if let points = feedback.credits {
                            Text("Points: \(String(points))")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.m)
                .frame(maxWidth: .infinity, alignment: .center)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(modelingVM.getBackgroundColor(feedback: feedback))
                }
                .animation(.easeInOut(duration: 0.5), value: showFeedback)
            }
            .padding([.leading, .bottom, .trailing], 20)
        }
    }
}

struct UnreferencedFeedbackView: View {
    @ObservedObject var modelingVM: ModelingExerciseViewModel
    @Binding var isStatusViewClicked: Bool

    var body: some View {
        Button {
            self.isStatusViewClicked = true
        } label: {
            Image(systemName: "ellipsis.message")
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
        .sheet(isPresented: $isStatusViewClicked) {
            VStack(alignment: .leading) {
                Button(R.string.localizable.close()) {
                    isStatusViewClicked = false
                }
                .padding([.leading, .top], .l)
                Text("\(Image(systemName: "ellipsis.message")) Additional feedback:")
                    .bold()
                    .padding(.m)
                List {
                    ForEach(modelingVM.unreferencedFeedbacks) { feedback in
                        let color = modelingVM.getBackgroundColor(feedback: feedback)
                        HStack(spacing: 3) {
                            if let points = feedback.credits {
                                Text("\(String(points)) Points:")
                                    .bold()
                                    .foregroundColor(color)
                            }
                            if let text = feedback.detailText {
                                Text(text)
                                    .foregroundColor(color)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .padding(.m)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(color, lineWidth: 1)
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundColor(color.opacity(0.1))
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .presentationDetents([.medium])
            }
        }
    }
}
