import SharedModels

/// The submitted response owns grading content; the draft only fills omitted submitted fields.
struct TrainingQuestionPresentation {
    let question: DTO.QuizQuestionTraining
    let answer: DTO.SubmittedAnswerFromLiveClient?
    let shortAnswer: DTO.ShortAnswerSubmittedAnswerAfterEvaluation?

    init(question original: DTO.QuizQuestionTraining, evaluation: DTO.SubmittedAnswerAfterEvaluation?, draft: DTO.SubmittedAnswerFromLiveClient?) {
        var question = TrainingProjection.answering(original)
        guard let evaluation else { self.question = question; answer = draft; shortAnswer = nil; return }
        if let evaluatedQuestion = evaluation.question { question.quizQuestionWithSolutionDTO = evaluatedQuestion }
        self.question = question
        switch evaluation {
        case .multipleChoice(let result):
            answer = result.selectedOptions == nil ? draft : evaluation.reviewAnswer
            shortAnswer = nil
        case .dragAndDrop(let result):
            answer = result.mappings == nil ? draft : evaluation.reviewAnswer
            shortAnswer = nil
        case .shortAnswer(var result):
            answer = result.submittedTexts == nil ? draft : evaluation.reviewAnswer
            if result.submittedTexts == nil, case .shortAnswer(let frozen) = draft {
                result.submittedTexts = frozen.submittedTexts?.map { .init(text: $0.text, spot: .init(id: $0.spot?.id)) }
            }
            shortAnswer = result
        }
    }
}
