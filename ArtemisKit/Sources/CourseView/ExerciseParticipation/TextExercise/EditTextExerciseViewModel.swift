//
//  EditTextExerciseViewModel.swift
//
//
//  Created by Nityananda Zbil on 14.06.24.
//

import Foundation

@Observable
final class EditTextExerciseViewModel {
    private let exerciseSubmissionService = TextExerciseSubmissionService()

    var text: String = ""
    var isSubmitted = false

    var isProblemStatementPresented = false
}
