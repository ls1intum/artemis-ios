//
//  ExerciseParticipationProblemButton.swift
//
//
//  Created by Nityananda Zbil on 15.06.24.
//

import SwiftUI

struct ExerciseParticipationProblemButton: View {
    @Binding var isProblemPresented: Bool

    var body: some View {
        Button {
            isProblemPresented = true
        } label: {
            Image(systemName: "newspaper")
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
