//
//  File.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.06.26.
//

import DesignLibrary
import SwiftUI

struct QuizTraingQuestionsView: View {

    @State private var viewModel: QuizTrainingViewModel

    init(courseId: Int) {
        _viewModel = State(initialValue: QuizTrainingViewModel(courseId: courseId))
    }

    var body: some View {
        DataStateView(data: $viewModel.questions) {
            await viewModel.loadQuestions()
        } content: { questions in
            Text("\(questions.count) questions")
        }
        .task(id: "loadQuestions") {
            if case .done = viewModel.questions {
                return
            }
            await viewModel.loadQuestions()
        }
    }
}
