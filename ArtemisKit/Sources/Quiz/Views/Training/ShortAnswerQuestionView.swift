//
//  ShortAnswerQuestionView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.06.26.
//

import SharedModels
import SwiftUI

struct ShortAnswerQuestionView: View {
    @Environment(QuizTrainingViewModel.self) private var viewModel

    let question: DTO.QuizQuestionTraining
    private let segments: [Segment]

    @State private var textInputs: [DTO.ShortAnswerSubmittedTextFromLiveClient]
    @FocusState private var focus: Segment?

    init(question: DTO.QuizQuestionTraining) {
        self.question = question
        self.segments = Segment.create(from: question.quizQuestionWithSolutionDTO.text)

        let inputs = segments.filter(\.isInput)
        self.textInputs = inputs.map {
            if case let .input(spot) = $0 {
                return .init(text: "", spot: .init(id: spot))
            } else {
                return .init()
            }
        }
    }

    var body: some View {
        ForEach(segments, id: \.self) { segment in
            switch segment {
            case .input(let spot):
                TextField("\(spot)", text: textBinding(for: spot))
                    .focused($focus, equals: segment)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.next)
                    .onSubmit {
                        // Focus next text field
                        if let index = segments.firstIndex(of: segment) {
                            let next = segments.suffix(segments.count - index - 1)
                            focus = next.first(where: \.isInput)
                        }
                    }
            case .text(let text):
                Text(LocalizedStringKey(text))
            }
        }
        .padding(.horizontal)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .disabled(viewModel.hasSubmitted)

        SubmitAnswerButton(questionId: question.id, isRated: question.isRated, answer: answer)
    }

    private var answer: QuizTrainingAnswer {
        .ShortAnswerSubmittedAnswerFromLiveClient(.init(
            .init(quizQuestion: .init(id: question.id),
                  submittedTexts: textInputs))
        )
    }

    func textBinding(for spot: Int64) -> Binding<String> {
        Binding {
            textInputs.first {
                $0.spot?.id == spot
            }?.text ?? ""
        } set: { newValue in
            textInputs = textInputs.map {
                if $0.spot?.id == spot {
                    return .init(text: newValue, spot: $0.spot)
                } else {
                    return $0
                }
            }
        }
    }
}

private enum Segment: Hashable {
    case text(text: String)
    case input(spot: Int64)

    var isInput: Bool {
        if case .input = self {
            return true
        } else {
            return false
        }
    }

    static func create(from text: String?) -> [Segment] {
        guard let text else { return [] }

        let regex = #/\[-spot\s+(\d+)\]/#

        let textSegments = text.split(separator: regex, omittingEmptySubsequences: true)
        var matches = text.matches(of: regex).map { String($0.output.1) }

        var result: [Segment] = []

        for segment in textSegments {
            result.append(.text(text: String(segment)))
            if let match = matches.first {
                result.append(.input(spot: Int64(match) ?? 0))
                matches.removeFirst()
            }
        }

        return result
    }
}
