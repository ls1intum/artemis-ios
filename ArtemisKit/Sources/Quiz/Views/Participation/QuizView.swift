//
//  QuizView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.07.26.
//

import SharedModels
import SwiftUI

struct QuizView: View {
    let endTime: Date?
    var questionsWithoutSolution: [DTO.QuizQuestionWithoutSolution]?
    var questionsWithSolution: [DTO.QuizQuestionWithSolution]?

    var body: some View {
        TabView {
            if let questionsWithSolution {
                ForEach(questionsWithSolution, id: \.hashValue) { question in
                    ScrollView {
                        VStack(alignment: .leading) {
                            switch question {
                            case .dragAndDrop(let dndQuestion):
                                DNDQuestionView(question: .init(quizQuestionWithSolutionDTO: .dragAndDrop(dndQuestion)),
                                                questionWithAnswer: dndQuestion)
                            case .multipleChoice(let mcQuestion):
                                MCQuestionView(question: .init(quizQuestionWithSolutionDTO: .multipleChoice(mcQuestion)),
                                               questionWithAnswer: mcQuestion)
                            case .shortAnswer(let saQuestion):
                                ShortAnswerQuestionView(question: .init(quizQuestionWithSolutionDTO: .shortAnswer(saQuestion)),
                                                        questionWithSolution: saQuestion)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else if let questionsWithoutSolution {
                Text("Questions without solution not yet supported")
            }
        }
        .tabViewStyle(.page)
        .environment(QuizTrainingViewModel(courseId: 0))
    }
}
