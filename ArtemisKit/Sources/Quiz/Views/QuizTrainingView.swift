//
//  QuizTrainingView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 01.06.26.
//

import SwiftUI

public struct QuizTrainingView: View {

    let courseId: Int

    public init(courseId: Int) {
        self.courseId = courseId
    }

    public var body: some View {
        NavigationStack {
            List {
                LeaderboardView(courseId: courseId)
            }
            .navigationTitle("Quiz Training")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}
