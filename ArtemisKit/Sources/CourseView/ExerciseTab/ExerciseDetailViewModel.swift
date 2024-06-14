//
//  ExerciseDetailViewModel.swift
//
//
//  Created by Nityananda Zbil on 14.06.24.
//

import Common
import SharedModels
import SwiftUI

@Observable
final class ExerciseDetailViewModel {
    let courseId: Int
    let exerciseId: Int

    var exercise: DataState<Exercise>

    var isFeedbackPresented = false
    var latestResultId: Int?
    var participationId: Int?

    // MARK: Web view

    var isWebViewLoading = true
    var urlRequest: URLRequest
    var webViewId = UUID()
    var webViewHeight = CGFloat.s
    /// We need a custom height calculation, otherwise the web view is often too small
    let webViewHeightJS = """
        if (document.querySelector("#problem-statement") != null) {
            document.querySelector("#problem-statement").scrollHeight;
        } else if (document.querySelector(".instructions__content") != null) {
            document.querySelector(".instructions__content").scrollHeight;
        } else {
            document.body.scrollHeight;
        }
        """

    init(courseId: Int, exerciseId: Int, exercise: DataState<Exercise>, urlRequest: URLRequest) {
        self.courseId = courseId
        self.exerciseId = exerciseId

        self.exercise = exercise

        self.urlRequest = urlRequest
    }
}

extension ExerciseDetailViewModel {
    var score: String {
        let score = exercise.value?.baseExercise.studentParticipations?
            .first?
            .baseParticipation
            .results?
            .filter { $0.rated ?? false }
            .max(by: { ($0.id ?? Int.min) > ($1.id ?? Int.min) })?
            .score ?? 0

        let maxPoints = exercise.value?.baseExercise.maxPoints ?? 0

        return (score * maxPoints / 100).rounded().clean
    }

    var isFeedbackButtonVisible: Bool {
        switch exercise.value {
        case .fileUpload, .programming, .text:
            return true
        default:
            return false
        }
    }

    var isExerciseParticipationAvailable: Bool {
        switch exercise.value {
        case .modeling:
            return true
        default:
            return false
        }
    }
}
