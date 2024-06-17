//
//  ExerciseParticipationAssessmentButton.swift
//
//
//  Created by Nityananda Zbil on 17.06.24.
//

import SwiftUI

struct ExerciseParticipationAssessmentButton: View {
    @Binding var isAssessmentPresented: Bool

    var body: some View {
        Button {
            self.isAssessmentPresented = true
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
    }
}
