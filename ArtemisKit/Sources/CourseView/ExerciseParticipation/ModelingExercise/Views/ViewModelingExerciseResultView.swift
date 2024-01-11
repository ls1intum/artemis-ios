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
    @State var isStatusViewClicked = false

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
                AssessmentView(modelingVM: modelingVM, isStatusViewClicked: $isStatusViewClicked)
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
                VStack(alignment: .leading) {
                    HStack {
                        Text("Element")
                            .bold()
                        Spacer()
                        Text("Points")
                            .bold()
                    }
                    Divider()
                    HStack {
                        if let reference = feedback.reference {
                            Text(reference.components(separatedBy: ":")[0])
                            if let name = modelingVM.getItemNameById(itemId: reference.components(separatedBy: ":")[1]) {
                                Text(name)
                                    .foregroundColor(Color.Artemis.artemisLightBlue)
                            }
                        }
                        Spacer()
                        if let points = feedback.credits {
                            Text(String(points))
                        }
                    }
                    if let text = feedback.text {
                        HStack(alignment: .top) {
                            Text("Feedback:")
                                .bold()
                            Text(text)
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundColor(modelingVM.getBackgroundColor(feedback: feedback))
                    }
                }
                .padding(.m)
                .frame(maxWidth: .infinity, alignment: .center)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(Color.Artemis.modalCardBackgroundColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 15)
        }
    }
}

struct AssessmentView: View {
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
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: .s) {
                    Button(R.string.localizable.close()) {
                        isStatusViewClicked = false
                    }
                    .padding(.top, .l)

                    Text("Assessment")
                        .font(.title)
                        .bold()
                        .padding(.vertical, .l)

                    HStack {
                        Text("Element")
                            .bold()
                        Spacer()
                        Text("Points")
                            .bold()
                    }

                    Divider()

                    ForEach(modelingVM.referencedFeedbacks) { feedback in
                        HStack {
                            if let reference = feedback.reference {
                                Text(reference.components(separatedBy: ":")[0])
                                if let name = modelingVM.getItemNameById(itemId: reference.components(separatedBy: ":")[1]) {
                                    Text(name)
                                        .foregroundColor(Color.Artemis.artemisLightBlue)
                                }
                            }
                            Spacer()
                            if let points = feedback.credits {
                                Text(String(points))
                            }
                        }
                        if let text = feedback.text {
                            HStack(alignment: .top) {
                                Text("Feedback:")
                                    .bold()
                                Text(text)
                                    .multilineTextAlignment(.leading)
                            }
                            .foregroundColor(modelingVM.getBackgroundColor(feedback: feedback))
                        }
                        Divider()
                    }

                    if !modelingVM.unreferencedFeedbacks.isEmpty {
                        VStack(alignment: .leading) {
                            Text("\(Image(systemName: "ellipsis.message")) Additional feedback:")
                                .font(.headline)
                                .bold()
                                .padding(.m)

                            ForEach(modelingVM.unreferencedFeedbacks) { feedback in
                                let color = modelingVM.getBackgroundColor(feedback: feedback)
                                HStack(alignment: .top) {
                                    if let points = feedback.credits {
                                        Text("\(String(points)) Points:")
                                            .bold()
                                            .foregroundColor(color)
                                    }
                                    if let text = feedback.detailText {
                                        Text(text)
                                            .multilineTextAlignment(.leading)
                                            .foregroundColor(color)
                                    }
                                }
                                .padding(.m)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(color, lineWidth: 1)
                                }
                                .background {
                                    RoundedRectangle(cornerRadius: 5)
                                        .foregroundColor(color.opacity(0.1))
                                }
                                .padding(.m)
                            }
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundColor(Color.Artemis.modalCardBackgroundColor)
                        }
                        .padding(.vertical, .l)
                    }
                }
                .padding(.horizontal, .m)
            }
        }
    }
}
