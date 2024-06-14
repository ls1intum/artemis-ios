//
//  EditTextExerciseViewModel.swift
//
//
//  Created by Nityananda Zbil on 14.06.24.
//

import Foundation

enum EditTextExerciseViewTab: String, CaseIterable, Identifiable {
    case submission
    case problemStatement

    var id: Self {
        self
    }
}

@Observable
final class EditTextExerciseViewModel {
    private let exerciseSubmissionService = TextExerciseSubmissionService()

    var tab: EditTextExerciseViewTab = .submission
    var text: String = ""
    var isSubmitted = false
}
