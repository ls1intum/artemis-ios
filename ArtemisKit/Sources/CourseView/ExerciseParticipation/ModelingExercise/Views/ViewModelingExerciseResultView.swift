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
        ZStack {
            if !modelingViewModel.diagramTypeUnsupported {
                if let model = modelingViewModel.umlModel, let type = model.type {
                    ApollonView(umlModel: model,
                                diagramType: type,
                                fontSize: 14.0,
                                themeColor: Color.Artemis.artemisBlue,
                                diagramOffset: modelingViewModel.diagramOffset,
                                isGridBackground: true) {
                        Canvas(rendersAsynchronously: true) { context, size in
                            modelingViewModel.renderHighlights(&context, size: size)
                        } symbols: {
                            modelingViewModel.generatePossibleSymbols()
                        }
                        .onTapGesture { tapLocation in
                            modelingViewModel.selectItem(at: tapLocation)
                        }
                    }
                }
                FeedbackViewPopOver(modelingViewModel: modelingViewModel)
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
            ToolbarItemGroup(placement: .principal) {
                SubmissionResultStatusView(exercise: modelingViewModel.exercise)
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                AssessmentViewButton(modelingViewModel: modelingViewModel, isStatusViewClicked: $isStatusViewClicked)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct FeedbackViewPopOver: View {
    @ObservedObject var modelingViewModel: ModelingExerciseViewModel

    var body: some View {
        if modelingViewModel.showFeedback,
           modelingViewModel.selectedItem != nil,
           let feedbackId = modelingViewModel.selectedFeedbackId,
           let feedback = modelingViewModel.getFeedback(byId: feedbackId) {
            VStack {
                Spacer()
                VStack(alignment: .leading) {
                    HStack {
                        Text(R.string.localizable.modelingFeedbackElement())
                            .bold()
                        Spacer()
                        Text(R.string.localizable.modelingFeedbackPoints())
                            .bold()
                    }
                    Divider()
                    HStack {
                        if let reference = feedback.reference {
                            Text(reference.components(separatedBy: ":")[0])
                            if let name = modelingViewModel.getItemNameById(itemId: reference.components(separatedBy: ":")[1]) {
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
                            Text(R.string.localizable.modelingFeedback())
                                .bold()
                            Text(text)
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundColor(modelingViewModel.getBackgroundColor(feedback: feedback))
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

private struct AssessmentViewButton: View {
    @ObservedObject var modelingViewModel: ModelingExerciseViewModel
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
            AssessmentView(modelingViewModel: modelingViewModel, isStatusViewClicked: $isStatusViewClicked)
        }
    }
}

private struct AssessmentView: View {
    @ObservedObject var modelingViewModel: ModelingExerciseViewModel
    @Binding var isStatusViewClicked: Bool

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: .s) {
                Button {
                    isStatusViewClicked = false
                } label: {
                    Text(R.string.localizable.close())
                }
                .padding(.top, .l)

                Text(R.string.localizable.modelingAssessment())
                    .font(.title)
                    .bold()
                    .padding(.vertical, .l)

                HStack {
                    Text(R.string.localizable.modelingFeedbackElement())
                        .bold()
                    Spacer()
                    Text(R.string.localizable.modelingFeedbackPoints())
                        .bold()
                }

                Divider()

                ForEach(modelingViewModel.referencedFeedbacks) { feedback in
                    HStack {
                        if let reference = feedback.reference {
                            Text(reference.components(separatedBy: ":")[0])
                            if let name = modelingViewModel.getItemNameById(itemId: reference.components(separatedBy: ":")[1]) {
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
                            Text(R.string.localizable.modelingFeedback())
                                .bold()
                            Text(text)
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundColor(modelingViewModel.getBackgroundColor(feedback: feedback))
                    }
                    Divider()
                }

                if !modelingViewModel.unreferencedFeedbacks.isEmpty {
                    VStack(alignment: .leading) {
                        Text("\(Image(systemName: "ellipsis.message")) \(R.string.localizable.modelingAdditionalFeedback())")
                            .font(.headline)
                            .bold()
                            .padding(.m)

                        ForEach(modelingViewModel.unreferencedFeedbacks) { feedback in
                            let color = modelingViewModel.getBackgroundColor(feedback: feedback)
                            HStack(alignment: .top) {
                                if let points = feedback.credits {
                                    Text("\(String(points)) \(R.string.localizable.modelingFeedbackPoints())")
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
