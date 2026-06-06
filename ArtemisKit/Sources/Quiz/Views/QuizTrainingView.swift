//
//  QuizTrainingView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 01.06.26.
//

import SwiftUI

public struct QuizTrainingView: View {

    @Environment(\.dismiss) private var dismiss

    let courseId: Int

    public init(courseId: Int) {
        self.courseId = courseId
    }

    public var body: some View {
        NavigationStack {
            List {
                LeaderboardView(courseId: courseId)
            }
            .navigationTitle(R.string.localizable.quizTraining())
            .toolbarTitleDisplayMode(.inlineLarge)
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(R.string.localizable.done()) {
                        dismiss()
                    }
                }
            }
        }
    }
}
