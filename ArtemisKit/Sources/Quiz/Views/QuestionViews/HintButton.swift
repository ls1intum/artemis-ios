//
//  HintButton.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 09.10.26.
//

import ReviewContent
import SwiftUI

struct HintButton: View {
    @Environment(QuizViewModel.self) private var viewModel
    let hint: String

    @State private var showHint = false

    var body: some View {
        Button {
            showHint = true
        } label: {
            Label((viewModel is QuizTrainingViewModel ? TrainingCopy.text("hint") : R.string.localizable.hint()), systemImage: "questionmark.circle.fill")
        }
        .labelStyle(.iconOnly)
        .frame(minWidth: 44, minHeight: 44)
        .popover(isPresented: $showHint, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            ScrollView(.vertical) {
                VStack {
                    Text((viewModel is QuizTrainingViewModel ? TrainingCopy.text("hint") : R.string.localizable.hint()))
                        .font(.title2)

                    if viewModel.usesSafeContent { SafeReviewContent(hint) } else { Text(hint).font(.body) }
                }
                .padding()
                .tint(.primary)
            }
            .frame(maxWidth: 280, minHeight: 200)
            .presentationCompactAdaptation(.none)
        }
    }
}
