//
//  ExerciseParticipationView.swift
//
//
//  Created by Nityananda Zbil on 10.12.23.
//

import SwiftUI

public struct ExerciseParticipationView: View {

    public init() {}

    public var body: some View {
        ContentUnavailableView {
            Label("Please wait…", systemImage: "list.bullet.clipboard")
        } description: {
            Text("This screen will refresh automatically, when the exercise starts.")
        } actions: {
            Button("Refresh") {
                // TODO
            }
        }
    }
}
