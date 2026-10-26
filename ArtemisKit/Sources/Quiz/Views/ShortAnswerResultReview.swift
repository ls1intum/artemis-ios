import Foundation
import ReviewContent
import SharedModels
import SwiftUI

/// Keeps server-evaluated fields separate from the live submission DTO.
struct ShortAnswerReviewPresentation {
    struct Answer {
        let spotID: Int64?
        let number: Int
        let text: String
        let isCorrect: Bool?
        let solutions: [String]
    }
    enum Segment { case text(String), answer(Answer) }
    let segments: [Segment]
    init(question: DTO.ShortAnswerQuizQuestionWithSolution, answer: DTO.ShortAnswerSubmittedAnswerAfterEvaluation?) {
        let text = question.text ?? ""
        let expression = try? NSRegularExpression(pattern: #"\[-spot\s+(\d+)\]"#)
        let nsText = text as NSString
        let matches = expression?.matches(in: text, range: NSRange(location: 0, length: nsText.length)) ?? []
        var segments: [Segment] = []
        var cursor = 0
        for match in matches {
            if match.range.location > cursor { segments.append(.text(nsText.substring(with: NSRange(location: cursor, length: match.range.location - cursor)))) }
            let number = Int(nsText.substring(with: match.range(at: 1))) ?? -1
            let spot = question.spots?.first(where: { $0.spotNr.map(Int.init) == number })
            let submitted = answer?.submittedTexts?.first(where: { $0.spot?.id != nil && $0.spot?.id == spot?.id })
            let solutions = question.correctMappings?.filter { $0.spot?.id == spot?.id && spot?.id != nil }.compactMap(\.solution?.text) ?? []
            segments.append(.answer(.init(spotID: spot?.id, number: number, text: submitted?.text ?? "", isCorrect: submitted?.isCorrect, solutions: solutions)))
            cursor = match.range.location + match.range.length
        }
        if cursor < nsText.length { segments.append(.text(nsText.substring(from: cursor))) }
        self.segments = segments
    }
    func answer(number: Int) -> Answer? {
        for case .answer(let answer) in segments where answer.number == number { return answer }
        return nil
    }
}

struct ShortAnswerResultReview: View {
    let presentation: ShortAnswerReviewPresentation
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(presentation.segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let text): SafeReviewContent(text)
                case .answer(let answer):
                    HStack {
                        Text(answer.text.isEmpty ? "—" : answer.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                        if let correct = answer.isCorrect {
                            Label(correct ? R.string.localizable.correct() : R.string.localizable.incorrect(), systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(correct ? .green : .red)
                        }
                    }.padding(8).background(Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: 8))
                    if answer.isCorrect == false, !answer.solutions.isEmpty {
                        GroupBox(R.string.localizable.solution()) {
                            ForEach(answer.solutions, id: \.self) { SafeReviewContent($0) }
                        }
                    }
                }
            }
        }.padding(.horizontal)
    }
}
