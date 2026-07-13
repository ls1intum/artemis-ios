//
//  SubmitAnswerButton.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 13.07.26.
//

import SharedModels
import SwiftUI

struct SubmitAnswerButton: View {
    let isTrainingMode: Bool

    let questionId: Int64?
    let isRated: Bool?
    let answer: DTO.SubmittedAnswerFromLiveClient

    @State private var isLoading = false

    var body: some View {
        if !isTrainingMode {
            SubmitTrainingAnswerButton(questionId: questionId, isRated: isRated, answer: answer)
        } else {
            SubmitLiveAnswerButton(answer: answer)
        }
    }
}
