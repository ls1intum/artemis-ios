//
//  ExerciseParticipationSubmitButton.swift
//
//
//  Created by Nityananda Zbil on 15.06.24.
//

import DesignLibrary
import SwiftUI

struct ExerciseParticipationSubmitButton: View {

    struct Delegate {
        var submit: () async throws -> Void
    }

    let delegate: Delegate

    @Binding var isSubmissionAlertPresented: Bool
    @Binding var isSubmissionSuccessful: Bool

    @State private var isSubmitting = false

    var body: some View {
        Button {
            submit()
        } label: {
            ZStack {
                Text(R.string.localizable.submitSubmission())
                    .opacity(isSubmitting ? 0 : 1)
                // Show a Progress View, whilst the submision is being submitted
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.Artemis.primaryButtonTextColor))
                }
            }
        }
        .buttonStyle(ArtemisButton(buttonColor: buttonColor, buttonTextColor: Color.Artemis.primaryButtonTextColor))
        .disabled(isSubmitting)
    }
}

private extension ExerciseParticipationSubmitButton {
    var buttonColor: Color {
        if isSubmissionAlertPresented {
            (isSubmissionSuccessful ? Color.Artemis.resultSuccess : Color.Artemis.resultFailedColor)
        } else {
            Color.Artemis.primaryButtonColor
        }
    }

    func submit() {
        isSubmitting = true
        Task {
            do {
                try await delegate.submit()
                isSubmissionSuccessful = true
            } catch {
                isSubmissionSuccessful = false
            }
            withAnimation {
                isSubmitting = false
                isSubmissionAlertPresented.toggle()
            }
        }
    }
}
